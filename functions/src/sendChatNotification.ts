import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Ensure firebase-admin is initialized (it might be initialized in other files, but safe to call)
if (!admin.apps.length) {
    admin.initializeApp();
}

/**
 * Cloud Function for sending chat notifications
 * Can be called by client to send notification to a specific user via token
 */
export const sendChatNotification = functions.https.onCall(async (data, context) => {
    // Verify that the request is made by an authenticated user
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "Only authenticated users can send notifications."
        );
    }

    const {
        token,
        title,
        body,
        data: customData,
        imageUrl,
    } = data;

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
