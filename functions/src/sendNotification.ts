import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Sends a targeted notification to a user.
 */
export const sendNotification = functions.https.onCall(async (data, context) => {
    // Verify auth
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "Only authenticated users can send notifications."
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
                title,
                body,
            },
            data: customData || {},
            token: token,
        };

        const response = await admin.messaging().send(message);
        console.log("Successfully sent message:", response);
        return { success: true, messageId: response };
    } catch (error) {
        console.error("Error sending message:", error);
        throw new functions.https.HttpsError(
            "internal",
            "Error sending notification",
            error
        );
    }
});
