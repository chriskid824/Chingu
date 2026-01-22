import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Ensure admin is initialized (it might be initialized in index.ts or other files, but safe to check)
if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Sends a push notification to a specific device using FCM token.
 *
 * Data payload:
 * - token: The FCM token of the recipient device
 * - title: Notification title
 * - body: Notification body
 * - data: Optional custom data map
 */
export const sendNotification = functions.https.onCall(async (data, context) => {
    // Verify authentication
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "The function must be called while authenticated."
        );
    }

    const { token, title, body, data: customData } = data;

    // Validate required fields
    if (!token || !title || !body) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "The function must be called with 'token', 'title', and 'body' arguments."
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
