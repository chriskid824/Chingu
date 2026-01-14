import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

interface BroadcastData {
    title: string;
    body: string;
    type: 'global' | 'targeted';
    targetUserIds?: string[];
    data?: Record<string, string>;
}

export const sendBroadcast = async (data: BroadcastData, context: functions.https.CallableContext) => {
    // 1. Authentication check
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'The function must be called while authenticated.');
    }

    // 2. Admin Authorization Check
    // SECURITY: This check ensures that only authorized users can send broadcasts.
    // In a production environment, you should use Custom Claims (e.g., context.auth.token.admin === true)
    // or verify the UID against a database of admins.

    // For now, we check if the user has the 'admin' custom claim.
    const isAdmin = context.auth.token.admin === true;

    // Alternatively, you can whitelist specific UIDs here for testing:
    // const adminUids = ['YOUR_ADMIN_UID_HERE'];
    // const isAdmin = context.auth.token.admin === true || adminUids.includes(context.auth.uid);

    if (!isAdmin) {
        // Log the unauthorized attempt
        console.warn(`Unauthorized broadcast attempt by user: ${context.auth.uid} (${context.auth.token.email})`);
        throw new functions.https.HttpsError('permission-denied', 'Only administrators can send broadcasts.');
    }

    const { title, body, type, targetUserIds, data: payloadData } = data;

    if (!title || !body) {
        throw new functions.https.HttpsError('invalid-argument', 'Title and body are required.');
    }

    // Ensure data payload values are strings (FCM requirement)
    const formattedData: Record<string, string> = {};
    if (payloadData) {
        for (const [key, value] of Object.entries(payloadData)) {
            formattedData[key] = String(value);
        }
    }

    try {
        if (type === 'global') {
            const message: admin.messaging.Message = {
                notification: {
                    title,
                    body,
                },
                data: formattedData,
                topic: 'global',
            };

            await admin.messaging().send(message);
            return { success: true, message: 'Global broadcast sent.' };

        } else if (type === 'targeted') {
            if (!targetUserIds || !Array.isArray(targetUserIds) || targetUserIds.length === 0) {
                throw new functions.https.HttpsError('invalid-argument', 'targetUserIds must be a non-empty array for targeted broadcasts.');
            }

            // Fetch tokens for users
            // Using getAll to fetch multiple documents in parallel
            const usersRef = admin.firestore().collection('users');
            const userRefs = targetUserIds.map(id => usersRef.doc(id));

            // Note: firestore.getAll supports up to 100 docs (or is it 10?).
            // For large lists, we should batch. Assuming reasonable batch size for now.
            // If targetUserIds is very large, this should be chunked.

            const chunkArray = <T>(arr: T[], size: number): T[][] => {
                return Array.from({ length: Math.ceil(arr.length / size) }, (v, i) =>
                    arr.slice(i * size, i * size + size)
                );
            };

            // Process in chunks of 100 to be safe
            const chunks = chunkArray(userRefs, 100);
            const tokens: string[] = [];

            for (const chunk of chunks) {
                const snapshots = await admin.firestore().getAll(...chunk);
                for (const snap of snapshots) {
                    if (snap.exists) {
                        const userData = snap.data();
                        if (userData && userData.fcmToken) {
                            tokens.push(userData.fcmToken);
                        }
                    }
                }
            }

            if (tokens.length === 0) {
                 return { success: false, message: 'No valid tokens found for targeted users.' };
            }

            // Send multicast
            const message: admin.messaging.MulticastMessage = {
                notification: {
                    title,
                    body,
                },
                data: formattedData,
                tokens: tokens,
            };

            const response = await admin.messaging().sendEachForMulticast(message);

            return {
                success: true,
                message: `Targeted broadcast processed. Success: ${response.successCount}, Failure: ${response.failureCount}.`,
                failureCount: response.failureCount,
                successCount: response.successCount
            };
        } else {
            throw new functions.https.HttpsError('invalid-argument', 'Invalid type. Must be global or targeted.');
        }
    } catch (error) {
        console.error('Error sending broadcast:', error);
        throw new functions.https.HttpsError('internal', 'Error sending broadcast.');
    }
};
