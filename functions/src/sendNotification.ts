import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

/**
 * Cloud Function for sending a single notification to a specific device
 *
 * Data parameters:
 * - token: FCM token of the target device
 * - title: Notification title
 * - body: Notification body
 * - data: (Optional) Custom data payload
 * - imageUrl: (Optional) Image URL
 */
export const sendNotification = functions.https.onCall(async (data, context) => {
    // Verify authentication
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "Only authenticated users can send notifications."
        );
    }

    const { token, title, body, data: customData, imageUrl } = data;

    // Validate required fields
    if (!token) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Target token is required."
        );
    }
    if (!title || !body) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Title and body are required."
        );
    }

    try {
        const message: admin.messaging.Message = {
            notification: {
                title,
                body,
                ...(imageUrl && { imageUrl }),
            },
            data: customData || {},
            token: token,
        };

        const response = await admin.messaging().send(message);
        console.log("Successfully sent message:", response);

        return { success: true, messageId: response };
    } catch (error) {
        console.error("Error sending notification:", error);
        throw new functions.https.HttpsError(
            "internal",
            "Failed to send notification.",
            error
        );
    }
});
