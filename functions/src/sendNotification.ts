import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Sends a push notification to a specific user.
 *
 * Data Params:
 * - recipientId: string (required)
 * - title: string (required)
 * - body: string (required)
 * - data: object (optional, custom data like actionType, actionData)
 */
export const sendNotification = functions.https.onCall(async (data, context) => {
    // 1. Authentication check
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "The function must be called while authenticated."
        );
    }

    const { recipientId, title, body, data: customData } = data;

    // 2. Validation
    if (!recipientId || !title || !body) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "The function must be called with 'recipientId', 'title', and 'body'."
        );
    }

    try {
        // 3. Get Recipient's FCM Token
        const userDoc = await admin.firestore().collection("users").doc(recipientId).get();

        if (!userDoc.exists) {
             throw new functions.https.HttpsError(
                "not-found",
                "Recipient user not found."
            );
        }

        const userData = userDoc.data();
        const fcmToken = userData?.fcmToken;

        if (!fcmToken) {
            console.log(`User ${recipientId} has no FCM token. Notification skipped.`);
            return { success: false, reason: "no-token" };
        }

        // 4. Send Notification
        const message = {
            notification: {
                title: title,
                body: body,
            },
            data: customData || {},
            token: fcmToken,
        };

        const response = await admin.messaging().send(message);
        console.log(`Successfully sent message to ${recipientId}:`, response);

        return { success: true, messageId: response };

    } catch (error) {
        console.error("Error sending notification:", error);
        throw new functions.https.HttpsError(
            "internal",
            "Unable to send notification",
            error
        );
    }
});
