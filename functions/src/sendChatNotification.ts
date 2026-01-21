import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Sends a chat notification to a specific device.
 *
 * Expected data:
 * - token: The FCM token of the recipient.
 * - title: The title of the notification (e.g., sender name).
 * - body: The body of the notification (e.g., message content).
 * - data: Optional data payload (e.g., chatRoomId, senderId).
 */
export const sendChatNotification = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "The function must be called while authenticated."
        );
    }

    const { token, title, body, data: messageData } = data;

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
        data: messageData || {},
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
