import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Cloud Function to send a push notification for a new chat message.
 *
 * Data payload:
 * - token: string (Target FCM token)
 * - title: string (Notification title, e.g. Sender Name)
 * - body: string (Notification body, e.g. Message content)
 * - data: Record<string, string> (Optional data payload)
 */
export const sendChatNotification = functions.https.onCall(async (data, context) => {
    // Verify authentication
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "The function must be called while authenticated."
        );
    }

    const { token, title, body, data: customData } = data;

    if (!token || !title || !body) {
         throw new functions.https.HttpsError(
            "invalid-argument",
            "The function must be called with arguments 'token', 'title', and 'body'."
        );
    }

    const message = {
        notification: {
            title: title,
            body: body,
        },
        data: customData || {},
        token: token,
    };

    try {
        const response = await admin.messaging().send(message);
        return { success: true, messageId: response };
    } catch (error) {
        console.error("Error sending chat notification:", error);
         throw new functions.https.HttpsError(
            "internal",
            "Error sending notification",
            error
        );
    }
});
