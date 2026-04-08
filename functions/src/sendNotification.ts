import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Initialize Firebase Admin if not already initialized
if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Cloud Function to send FCM notifications to specific users.
 *
 * Usage:
 * - Single user: { targetUserId: "uid", title: "...", body: "..." }
 * - Multiple users: { targetUserIds: ["uid1", "uid2"], title: "...", body: "..." }
 */
export const sendNotification = functions.https.onCall(async (data, context) => {
    // Verify that the request is made by an authenticated user
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "Only authenticated users can send notifications."
        );
    }

    const {
        targetUserId,
        targetUserIds,
        title,
        body,
        data: customData,
        imageUrl,
    } = data;

    // Validate required fields
    if (!title || !body) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Title and body are required."
        );
    }

    if (!targetUserId && (!targetUserIds || targetUserIds.length === 0)) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Must specify targetUserId or targetUserIds."
        );
    }

    try {
        const db = admin.firestore();
        let userIds: string[] = [];

        if (targetUserIds && Array.isArray(targetUserIds)) {
            userIds = [...targetUserIds];
        }
        if (targetUserId && !userIds.includes(targetUserId)) {
            userIds.push(targetUserId);
        }

        // Remove duplicates
        userIds = [...new Set(userIds)];

        if (userIds.length === 0) {
             throw new functions.https.HttpsError(
                "invalid-argument",
                "No valid target user IDs provided."
            );
        }

        // Fetch user documents to get tokens
        const userRefs = userIds.map(id => db.collection("users").doc(id));
        const userDocs = await db.getAll(...userRefs);

        const validTargets = userDocs
            .map(doc => ({ id: doc.id, token: doc.data()?.fcmToken }))
            .filter(target => target.token);

        if (validTargets.length === 0) {
            throw new functions.https.HttpsError(
                "not-found",
                "No valid FCM tokens found for the specified users."
            );
        }

        const notificationPayload = {
            title,
            body,
            ...(imageUrl && { imageUrl }),
        };

        // Prepare custom data (ensure values are strings)
        const formattedData: { [key: string]: string } = {};
        if (customData) {
            for (const [key, value] of Object.entries(customData)) {
                formattedData[key] = String(value);
            }
        }

        // Send notification
        if (validTargets.length === 1) {
            const target = validTargets[0];
            const message = {
                notification: notificationPayload,
                data: formattedData,
                token: target.token,
            };

            const response = await admin.messaging().send(message);
            console.log(`Successfully sent notification to ${target.id}:`, response);

            return {
                success: true,
                successCount: 1,
                failureCount: 0,
                messageId: response
            };
        } else {
            const tokens = validTargets.map(t => t.token);
            const message = {
                notification: notificationPayload,
                data: formattedData,
                tokens: tokens,
            };

            const response = await admin.messaging().sendEachForMulticast(message);
            console.log(`Successfully sent ${response.successCount} messages; ${response.failureCount} failed.`);

            // Log failures if any
            if (response.failureCount > 0) {
                 response.responses.forEach((resp, idx) => {
                    if (!resp.success) {
                        console.error(`Error sending to token for user ${validTargets[idx].id}:`, resp.error);
                    }
                });
            }

            return {
                success: true,
                successCount: response.successCount,
                failureCount: response.failureCount,
                totalTargets: validTargets.length
            };
        }

    } catch (error) {
        console.error("Error sending notification:", error);
        if (error instanceof functions.https.HttpsError) {
            throw error;
        }
        throw new functions.https.HttpsError(
            "internal",
            "Failed to send notification.",
            error
        );
    }
});
