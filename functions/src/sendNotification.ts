import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Cloud Function to send a push notification to a specific user.
 *
 * Expected data:
 * - recipientId: string (required)
 * - title: string (required)
 * - body: string (required)
 * - data: Record<string, string> (optional)
 */
export const sendNotification = functions.https.onCall(async (data, context) => {
    // 1. Authenticated check
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "The function must be called while authenticated."
        );
    }

    const { recipientId, title, body, data: customData } = data;

    // 2. Validate input
    if (!recipientId || !title || !body) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "The function must be called with arguments 'recipientId', 'title', and 'body'."
        );
    }

    try {
        // 3. Get recipient's FCM token
        const userDoc = await admin.firestore().collection("users").doc(recipientId).get();
        if (!userDoc.exists) {
             throw new functions.https.HttpsError(
                "not-found",
                `User with ID ${recipientId} not found.`
            );
        }

        const userData = userDoc.data();
        const fcmToken = userData?.fcmToken;

        if (!fcmToken) {
            console.log(`User ${recipientId} has no FCM token. Skipping notification.`);
            return { success: false, reason: "no_token" };
        }

        // 4. Send notification
        const message: admin.messaging.Message = {
            token: fcmToken,
            notification: {
                title: title,
                body: body,
            },
            data: customData || {},
        };

        const response = await admin.messaging().send(message);
        console.log(`Successfully sent message to ${recipientId}:`, response);

        return { success: true, messageId: response };

    } catch (error) {
        console.error("Error sending notification:", error);
        throw new functions.https.HttpsError(
            "internal",
            "Failed to send notification",
            error
        );
    }
});
