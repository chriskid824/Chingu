import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

/**
 * Sends a chat notification to a specific device.
 *
 * Expected data:
 * - token: string (FCM token of the recipient)
 * - title: string (Sender's name)
 * - body: string (Message content)
 * - data: object (Optional custom data, e.g. chatRoomId)
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

    // Validate inputs
    if (!token || !title || !body) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "The function must be called with argument 'token', 'title' and 'body'."
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
