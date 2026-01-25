import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Helper to send multicast messages in batches of 500
 */
async function sendMulticastBatched(
    tokens: string[],
    title: string,
    body: string,
    imageUrl?: string,
    customData?: { [key: string]: string }
): Promise<{ successCount: number; failureCount: number }> {
    let successCount = 0;
    let failureCount = 0;

    // FCM limit is 500 tokens per multicast message
    const BATCH_SIZE = 500;
    const chunks = [];
    for (let i = 0; i < tokens.length; i += BATCH_SIZE) {
        chunks.push(tokens.slice(i, i + BATCH_SIZE));
    }

    for (const chunk of chunks) {
        const message: admin.messaging.MulticastMessage = {
            notification: {
                title,
                body,
                ...(imageUrl && { imageUrl }),
            },
            data: customData || {},
            tokens: chunk,
        };

        const batchResponse = await admin.messaging().sendEachForMulticast(message);
        successCount += batchResponse.successCount;
        failureCount += batchResponse.failureCount;
    }

    return { successCount, failureCount };
}

/**
 * Cloud Function for sending broadcast notifications
 * Can be called by admin to send global or targeted notifications
 * 
 * Usage:
 * - Global broadcast: targetAll = true
 * - City-specific: targetCities = ["Taipei", "Taichung"]
 * - User-specific: targetUserIds = ["uid1", "uid2"]
 */
export const sendBroadcast = functions.https.onCall(async (data, context) => {
    // Verify that the request is made by an authenticated user
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "Only authenticated users can send broadcasts."
        );
    }

    // Verify admin role
    const adminDoc = await admin.firestore()
        .collection("admins")
        .doc(context.auth.uid)
        .get();

    if (!adminDoc.exists) {
        throw new functions.https.HttpsError(
            "permission-denied",
            "Only admins can send broadcast notifications."
        );
    }

    const {
        title,
        body,
        data: customData,
        targetAll = false,
        targetCities = [],
        targetUserIds = [],
        imageUrl,
    } = data;

    // Validate required fields
    if (!title || !body) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Title and body are required."
        );
    }

    try {
        let response;
        let targetType = "unknown";

        if (targetAll) {
            targetType = "all";
            // Send to all users - use topic subscription
            const message: admin.messaging.Message = {
                notification: {
                    title: title,
                    body: body,
                    ...(imageUrl && { imageUrl }),
                },
                data: customData || {},
                topic: "all_users",
            };

            const msgId = await admin.messaging().send(message);
            console.log("Successfully sent broadcast to all users:", msgId);

            response = { success: true, messageId: msgId, recipients: "all" };

        } else if (targetUserIds && targetUserIds.length > 0) {
            targetType = "users";
            // Send to specific users
            const tokens: string[] = [];

            // Batch user queries (Firestore 'in' limit is 10)
            const chunks = [];
            for (let i = 0; i < targetUserIds.length; i += 10) {
                chunks.push(targetUserIds.slice(i, i + 10));
            }

            for (const chunk of chunks) {
                const usersSnapshot = await admin.firestore()
                    .collection("users")
                    .where(admin.firestore.FieldPath.documentId(), "in", chunk)
                    .get();

                usersSnapshot.docs.forEach((doc) => {
                    const token = doc.data().fcmToken;
                    if (token) tokens.push(token);
                });
            }

            if (tokens.length > 0) {
                const { successCount, failureCount } = await sendMulticastBatched(
                    tokens, title, body, imageUrl, customData
                );

                console.log(`Successfully sent ${successCount} messages, failed ${failureCount}`);

                response = {
                    success: true,
                    successCount,
                    failureCount,
                    totalTargets: tokens.length,
                };
            } else {
                response = {
                    success: false,
                    message: "No users found with FCM tokens for the specified criteria."
                };
            }

        } else if (targetCities && targetCities.length > 0) {
            targetType = "cities";
            // Send to users in specific cities
            const tokens: string[] = [];

            // Batch city queries
            const chunks = [];
            for (let i = 0; i < targetCities.length; i += 10) {
                chunks.push(targetCities.slice(i, i + 10));
            }

            for (const chunk of chunks) {
                const usersSnapshot = await admin.firestore()
                    .collection("users")
                    .where("city", "in", chunk)
                    .get();

                usersSnapshot.docs.forEach((doc) => {
                    const token = doc.data().fcmToken;
                    if (token) tokens.push(token);
                });
            }

            if (tokens.length > 0) {
                const { successCount, failureCount } = await sendMulticastBatched(
                    tokens, title, body, imageUrl, customData
                );

                response = {
                    success: true,
                    successCount,
                    failureCount,
                    totalTargets: tokens.length,
                };
            } else {
                 response = {
                    success: false,
                    message: "No users found with FCM tokens for the specified criteria."
                };
            }

        } else {
            throw new functions.https.HttpsError(
                "invalid-argument",
                "Must specify targetAll, targetUserIds, or targetCities."
            );
        }

        // Log the broadcast
        await admin.firestore().collection("broadcast_logs").add({
            title,
            body,
            targetType,
            targetIds: targetUserIds.length > 0 ? targetUserIds : targetCities,
            sentBy: context.auth.uid,
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
            result: response,
        });

        return response;

    } catch (error) {
        console.error("Error sending broadcast:", error);
        throw new functions.https.HttpsError(
            "internal",
            "Failed to send broadcast notification.",
            error
        );
    }
});
