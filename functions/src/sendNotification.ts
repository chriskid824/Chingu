import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Ensure admin is initialized (idempotent check)
if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Cloud Function for sending a single notification to a user.
 *
 * Usage:
 * call({
 *   targetUserId: "uid",
 *   title: "Sender Name",
 *   body: "Message preview...",
 *   data: { "key": "value" }
 * })
 */
export const sendNotification = functions.https.onCall(async (data, context) => {
    // Verify authentication
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "Only authenticated users can send notifications."
        );
    }

    const { targetUserId, title, body, data: customData } = data;

    // Validate required fields
    if (!targetUserId || !title || !body) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "targetUserId, title, and body are required."
        );
    }

    try {
        // Fetch target user's FCM token
        const userDoc = await admin.firestore().collection("users").doc(targetUserId).get();

        if (!userDoc.exists) {
            throw new functions.https.HttpsError(
                "not-found",
                "Target user not found."
            );
        }

        const userData = userDoc.data();
        const fcmToken = userData?.fcmToken;

        if (!fcmToken) {
            console.log(`User ${targetUserId} has no FCM token. Skipping notification.`);
            return { success: false, reason: "no_token" };
        }

        // Prepare the message
        const message = {
            notification: {
                title: title,
                body: body,
            },
            data: customData || {},
            token: fcmToken,
        };

        // Send the message
        const response = await admin.messaging().send(message);
        console.log("Successfully sent notification:", response);

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
