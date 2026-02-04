import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Cloud Function for sending chat notifications
 * Can be called by authenticated users to send a notification to a specific token
 */
export const sendChatNotification = functions.https.onCall(async (data, context) => {
    // Verify that the request is made by an authenticated user
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "Only authenticated users can send chat notifications."
        );
    }

    const { token, title, body, imageUrl } = data;

    // Validate required fields
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
                ...(imageUrl && { imageUrl }),
            },
            token: token,
            data: {
                type: 'chat',
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
            },
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
