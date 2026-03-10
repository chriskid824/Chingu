import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

/**
 * Sends a notification to a specific user via FCM.
 * This is a callable function intended to be called from the client app.
 */
export const sendNotification = functions.https.onCall(async (data, context) => {
    // 1. Verify Authentication
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "The function must be called while authenticated."
        );
    }

    const { token, title, body, data: customData } = data;

    // 2. Validate Inputs
    if (!token || !title || !body) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "The function must be called with arguments 'token', 'title', and 'body'."
        );
    }

    try {
        // 3. Construct Message
        const message: admin.messaging.Message = {
            token: token,
            notification: {
                title: title,
                body: body,
            },
            data: customData || {},
        };

        // 4. Send Message
        const response = await admin.messaging().send(message);

        console.log(`Successfully sent notification to ${token}: ${response}`);
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
