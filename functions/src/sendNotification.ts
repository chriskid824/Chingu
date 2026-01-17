import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Initialize admin app if not already initialized
if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Cloud Function to send a notification to a specific user
 *
 * Arguments:
 * - targetUserId: string (required)
 * - title: string (required)
 * - body: string (required)
 * - data: map (optional) - Custom data to send with notification
 * - imageUrl: string (optional)
 *
 * Returns:
 * - success: boolean
 * - messageId: string (if successful)
 */
export const sendNotification = functions.https.onCall(async (data, context) => {
    // 1. Authenticate the user
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "The function must be called while authenticated."
        );
    }

    const { targetUserId, title, body, data: customData, imageUrl } = data;

    // 2. Validate input
    if (!targetUserId || typeof targetUserId !== "string") {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "The function must be called with a valid 'targetUserId'."
        );
    }
    if (!title || typeof title !== "string") {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "The function must be called with a 'title'."
        );
    }
    if (!body || typeof body !== "string") {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "The function must be called with a 'body'."
        );
    }

    try {
        // 3. Get target user's FCM token
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
            console.log(`User ${targetUserId} has no FCM token. Skipping notification.`);
            return {
                success: false,
                reason: "no-token"
            };
        }

        // 4. Construct the message
        const message: admin.messaging.Message = {
            notification: {
                title,
                body,
                ...(imageUrl && { imageUrl }),
            },
            data: customData || {},
            token: fcmToken,
        };

        // 5. Send the notification
        const messageId = await admin.messaging().send(message);

        console.log(`Successfully sent notification to user ${targetUserId}. Message ID: ${messageId}`);

        return {
            success: true,
            messageId: messageId
        };

    } catch (error) {
        console.error("Error sending notification:", error);

        // Check if error is due to invalid token
        if (error instanceof Error && (error as any).code === 'messaging/registration-token-not-registered') {
             // Optionally remove the invalid token from the user document
             // await admin.firestore().collection("users").doc(targetUserId).update({ fcmToken: admin.firestore.FieldValue.delete() });
             return {
                 success: false,
                 reason: "invalid-token"
             };
        }

        throw new functions.https.HttpsError(
            "internal",
            "Error sending notification",
            error
        );
    }
});
