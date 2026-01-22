import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Cloud Function for sending a notification to a specific user
 *
 * Usage:
 * - Call with { targetUserId, title, body, imageUrl, data }
 */
export const sendNotification = functions.https.onCall(async (data, context) => {
    // 1. Verify user identity
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "The function must be called while authenticated."
        );
    }

    const { targetUserId, title, body, imageUrl, data: customData } = data;

    // Validate required fields
    if (!targetUserId || !title || !body) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "The function must be called with arguments 'targetUserId', 'title', and 'body'."
        );
    }

    try {
        // 2. Get target user FCM Tokens
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
            console.log(`User ${targetUserId} has no FCM token.`);
            return { success: false, message: "User has no FCM token" };
        }

        // 3. Send notification
        const message = {
            notification: {
                title,
                body,
                ...(imageUrl && { imageUrl }),
            },
            data: {
                ...customData,
                senderId: context.auth.uid,
                click_action: "FLUTTER_NOTIFICATION_CLICK",
            },
            token: fcmToken,
        };

        const response = await admin.messaging().send(message);
        console.log(`Successfully sent notification to user ${targetUserId}:`, response);

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
