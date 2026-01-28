import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Conditional initialization to avoid "default app already exists" errors
if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Cloud Function to send a push notification to a specific device.
 *
 * Arguments:
 * - token: string (Required) - The FCM token of the recipient.
 * - title: string (Required) - The title of the notification.
 * - body: string (Required) - The body text of the notification.
 * - imageUrl: string (Optional) - URL of an image to display.
 * - data: map (Optional) - Custom data payload.
 */
export const sendNotification = functions.https.onCall(async (data, context) => {
    // 1. Verify Authentication
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "The function must be called while authenticated."
        );
    }

    const { token, title, body, imageUrl, data: customData } = data;

    // 2. Validate Arguments
    if (!token || !title || !body) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "The function must be called with arguments \"token\", \"title\" and \"body\"."
        );
    }

    // 3. Construct Message
    const message: admin.messaging.Message = {
        token: token,
        notification: {
            title,
            body,
            ...(imageUrl && { imageUrl }),
        },
        data: customData || {},
    };

    // 4. Send Notification
    try {
        const response = await admin.messaging().send(message);
        console.log("Successfully sent message:", response);
        return { success: true, messageId: response };
    } catch (error) {
        console.error("Error sending notification:", error);
        throw new functions.https.HttpsError(
            "internal",
            "Error sending notification",
            error
        );
    }
});
