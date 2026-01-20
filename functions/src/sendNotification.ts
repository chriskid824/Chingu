import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Cloud Function for sending a notification to a specific user
 *
 * Data payload:
 * - targetUserId: string (Required)
 * - title: string (Required)
 * - body: string (Required)
 * - imageUrl: string (Optional)
 * - data: Record<string, string> (Optional)
 */
export const sendNotification = functions.https.onCall(async (data, context) => {
    // 1. Verify user identity
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "Only authenticated users can send notifications."
        );
    }

    const { targetUserId, title, body, imageUrl, data: customData } = data;

    // 2. Validate input
    if (!targetUserId || !title || !body) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "targetUserId, title, and body are required."
        );
    }

    try {
        // 3. Get target user's FCM token
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
            return { success: false, reason: "no_token" };
        }

        // 4. Send notification
        const message: admin.messaging.Message = {
            token: fcmToken,
            notification: {
                title: title,
                body: body,
                ...(imageUrl && { imageUrl }),
            },
            data: customData || {},
        };

        const response = await admin.messaging().send(message);
        console.log(`Successfully sent message to ${targetUserId}:`, response);

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
