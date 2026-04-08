import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Initialize admin app if not already initialized
if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Cloud Function to send a notification to a specific user.
 *
 * Expected data:
 * - targetUserId: string (Required)
 * - title: string (Required)
 * - body: string (Required)
 * - data: Record<string, string> (Optional)
 * - imageUrl: string (Optional)
 */
export const sendNotification = functions.https.onCall(async (data, context) => {
    // 1. Verify user identity
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "The function must be called while authenticated."
        );
    }

    const { targetUserId, title, body, data: customData, imageUrl } = data;

    // Validate required fields
    if (!targetUserId || !title || !body) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "targetUserId, title, and body are required."
        );
    }

    try {
        // 2. Get target user's FCM Token
        const userDoc = await admin.firestore().collection("users").doc(targetUserId).get();

        if (!userDoc.exists) {
            throw new functions.https.HttpsError(
                "not-found",
                "Target user not found."
            );
        }

        const userData = userDoc.data();
        const fcmToken = userData?.fcmToken;

        if (!fcmToken) {
            console.warn(`User ${targetUserId} has no FCM token.`);
            return {
                success: false,
                reason: "no_token_found"
            };
        }

        // 3. Send notification
        const message: admin.messaging.Message = {
            notification: {
                title,
                body,
                ...(imageUrl && { imageUrl }),
            },
            data: customData || {},
            token: fcmToken,
        };

        const response = await admin.messaging().send(message);

        return {
            success: true,
            messageId: response
        };

    } catch (error) {
        console.error("Error sending notification:", error);
        throw new functions.https.HttpsError(
            "internal",
            "Failed to send notification.",
            error
        );
    }
});
