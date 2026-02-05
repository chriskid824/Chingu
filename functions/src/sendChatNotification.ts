import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

/**
 * Cloud Function for sending chat notifications
 *
 * Accepts:
 * - token: string (FCM token of recipient)
 * - title: string (Sender name)
 * - body: string (Message preview)
 * - data: object (Optional custom data, e.g., chatRoomId)
 */
export const sendChatNotification = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "Only authenticated users can send chat notifications."
        );
    }

    const { token, title, body, data: customData } = data;

    if (!token || !title || !body) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Token, title, and body are required."
        );
    }

    try {
        const message = {
            notification: {
                title: title,
                body: body,
            },
            data: customData || {},
            token: token,
        };

        const response = await admin.messaging().send(message);
        console.log("Successfully sent chat notification:", response);

        return { success: true, messageId: response };
    } catch (error) {
        console.error("Error sending chat notification:", error);
        throw new functions.https.HttpsError(
            "internal",
            "Failed to send chat notification.",
            error
        );
    }
});
