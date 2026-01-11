import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Interface for the request data
interface BroadcastRequest {
    title: string;
    body: string;
    target: 'all' | 'filtered';
    filters?: {
        gender?: string;
        minAge?: number;
        maxAge?: number;
        city?: string;
        isActiveRecentDays?: number;
    };
    dryRun?: boolean;
}

// Interface for the response data
interface BroadcastResponse {
    success: boolean;
    message: string;
    userCount: number;
    tokenCount: number;
    successCount?: number;
    failureCount?: number;
}

export const sendBroadcast = functions.https.onCall(async (data: BroadcastRequest, context): Promise<BroadcastResponse> => {
    // 1. Authentication Check
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'The function must be called while authenticated.');
    }

    const uid = context.auth.uid;

    // Optional: Verify admin privileges
    // For now, we allow test@gmail.com and any user with isAdmin=true in Firestore
    try {
        const callerRef = admin.firestore().collection('users').doc(uid);
        const callerDoc = await callerRef.get();
        const callerData = callerDoc.data();

        const isEmailAdmin = callerData?.email === 'test@gmail.com';
        const isFlagAdmin = callerData?.isAdmin === true;

        if (!isEmailAdmin && !isFlagAdmin) {
            // For development/demo purposes, we might log a warning but allow it,
            // or strictly enforce it. Given this is a system function, let's enforce.
            console.warn(`User ${uid} (${callerData?.email}) attempting to broadcast without explicit admin rights.`);
            throw new functions.https.HttpsError('permission-denied', 'User is not authorized to send broadcasts.');
        }
    } catch (e) {
        console.error('Error verifying admin status:', e);
        // Fail open or closed? Closed is safer.
        throw new functions.https.HttpsError('permission-denied', 'Could not verify user permissions.');
    }

    // 2. Input Validation
    const { title, body, target, filters, dryRun } = data;

    if (!title || !body) {
        throw new functions.https.HttpsError('invalid-argument', 'Title and body are required.');
    }

    // 3. Build Query
    // We start with a basic collection reference
    let query: admin.firestore.Query = admin.firestore().collection('users');

    // Apply filters
    if (target === 'filtered' && filters) {
        // Equality filters can be chained easily
        if (filters.gender) {
            query = query.where('gender', '==', filters.gender);
        }
        if (filters.city) {
            query = query.where('city', '==', filters.city);
        }

        // Inequality filters (Age)
        // Note: Firestore allows inequality on only one field per query without advanced indexes.
        // We will prioritize filtering Age in the query if provided.
        if (filters.minAge !== undefined) {
             query = query.where('age', '>=', filters.minAge);
        }
        if (filters.maxAge !== undefined) {
             query = query.where('age', '<=', filters.maxAge);
        }
    }

    try {
        const snapshot = await query.get();

        // 4. In-Memory Filtering & Token Extraction
        const tokens: string[] = [];
        let userCount = 0;

        // Calculate date for active check
        let activeCutoff: Date | null = null;
        if (target === 'filtered' && filters?.isActiveRecentDays) {
            const d = new Date();
            d.setDate(d.getDate() - filters.isActiveRecentDays);
            activeCutoff = d;
        }

        snapshot.forEach(doc => {
            const userData = doc.data();

            // In-memory filter: isActiveRecentDays
            // We do this in memory to avoid "inequality on multiple fields" error if age was also filtered.
            if (activeCutoff) {
                const lastLoginTimestamp = userData.lastLogin;
                if (!lastLoginTimestamp) return; // Skip if no login data

                // Handle Firestore Timestamp or JS Date
                const lastLoginDate = (lastLoginTimestamp instanceof admin.firestore.Timestamp)
                    ? lastLoginTimestamp.toDate()
                    : new Date(lastLoginTimestamp);

                if (lastLoginDate < activeCutoff) {
                    return; // Skip inactive users
                }
            }

            userCount++;

            // Extract tokens
            // Check 'fcmToken' (string)
            if (userData.fcmToken && typeof userData.fcmToken === 'string' && userData.fcmToken.length > 0) {
                tokens.push(userData.fcmToken);
            }
            // Check 'fcmTokens' (array)
            if (userData.fcmTokens && Array.isArray(userData.fcmTokens)) {
                userData.fcmTokens.forEach((t: any) => {
                    if (typeof t === 'string' && t.length > 0) tokens.push(t);
                });
            }
        });

        // Deduplicate tokens
        const uniqueTokens = [...new Set(tokens)];

        // 5. Handle Dry Run
        if (dryRun) {
            return {
                success: true,
                message: `Dry run complete. Matching users: ${userCount}. Unique tokens found: ${uniqueTokens.length}.`,
                userCount,
                tokenCount: uniqueTokens.length
            };
        }

        if (uniqueTokens.length === 0) {
             return {
                success: true,
                message: 'No active devices found for the selected criteria.',
                userCount,
                tokenCount: 0
            };
        }

        // 6. Send Notifications
        const payload: admin.messaging.MulticastMessage = {
            notification: {
                title: title,
                body: body,
            },
            data: {
                type: 'system_broadcast', // Custom type for app handling
                title: title,             // Redundant but useful for data-only handling
                message: body,            // Redundant but useful for data-only handling
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
            },
            tokens: [], // Will be set in batches
            android: {
                priority: 'high',
                notification: {
                     channelId: 'channel_system', // Use the system channel defined in app
                }
            },
            apns: {
                payload: {
                    aps: {
                        sound: 'default',
                        alert: {
                            title: title,
                            body: body,
                        }
                    },
                },
            },
        };

        // Batch send (limit 500 per batch)
        const batchSize = 500;
        let successCount = 0;
        let failureCount = 0;

        for (let i = 0; i < uniqueTokens.length; i += batchSize) {
            const batchTokens = uniqueTokens.slice(i, i + batchSize);
            const batchPayload = { ...payload, tokens: batchTokens };

            const response = await admin.messaging().sendEachForMulticast(batchPayload);

            successCount += response.successCount;
            failureCount += response.failureCount;

            // Optional: cleanup invalid tokens
            if (response.failureCount > 0) {
                const invalidTokens: string[] = [];
                response.responses.forEach((resp, idx) => {
                    if (!resp.success && (
                        resp.error?.code === 'messaging/invalid-registration-token' ||
                        resp.error?.code === 'messaging/registration-token-not-registered'
                    )) {
                        invalidTokens.push(batchTokens[idx]);
                    }
                });

                if (invalidTokens.length > 0) {
                     // In a real app, we should remove these tokens from Firestore.
                     // console.log(`Found ${invalidTokens.length} invalid tokens.`);
                }
            }
        }

        return {
            success: true,
            message: `Broadcast sent. Success: ${successCount}, Failure: ${failureCount}.`,
            userCount,
            tokenCount: uniqueTokens.length,
            successCount,
            failureCount
        };

    } catch (error) {
        console.error('Error in sendBroadcast:', error);
        throw new functions.https.HttpsError('internal', 'An internal error occurred while processing the broadcast.');
    }
});
