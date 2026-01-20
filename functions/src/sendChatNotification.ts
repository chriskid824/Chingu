import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Sends a chat notification to a specific device.
 *
 * Arguments:
 * - token: The FCM token of the recipient.
 * - title: The title of the notification (usually the sender's name).
 * - body: The body of the notification (the message text).
 * - data: Optional custom data (e.g., chatRoomId, senderId).
 */
export const sendChatNotification = functions.https.onCall(async (data, context) => {
    // 1. Authenticate User
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "The function must be called while authenticated."
        );
    }

    const { token, title, body, data: customData } = data;

    // 2. Validate Parameters
    if (!token || !title || !body) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "The function must be called with 'token', 'title', and 'body' arguments."
        );
    }

    try {
        // 3. Send Notification
        const message = {
            notification: {
                title: title,
                body: body,
            },
            data: customData || {},
            token: token,
        };

        // Add Android specific configuration for high priority
        const androidConfig = {
            priority: 'high',
            notification: {
                channelId: 'chat_messages',
                clickAction: 'FLUTTER_NOTIFICATION_CLICK',
            },
        };

        // Add APNs specific configuration
        const apnsConfig = {
            payload: {
                aps: {
                    sound: 'default',
                    contentAvailable: true,
                },
            },
        };

        const fullMessage = {
            ...message,
            android: androidConfig,
            apns: apnsConfig,
        };

        const response = await admin.messaging().send(fullMessage as admin.messaging.Message);
        console.log("Successfully sent chat notification:", response);

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
