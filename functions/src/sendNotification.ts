import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Cloud Function to send FCM notification to a specific user.
 *
 * Arguments:
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
            "The function must be called while authenticated."
        );
    }

    const { targetUserId, title, body, imageUrl, data: customData } = data;

    // Validate required fields
    if (!targetUserId || !title || !body) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "The function must be called with argument 'targetUserId', 'title' and 'body'."
        );
    }

    try {
        // 2. Get target user FCM Tokens
        const userDoc = await admin.firestore().collection("users").doc(targetUserId).get();

        if (!userDoc.exists) {
            throw new functions.https.HttpsError(
                "not-found",
                `User with ID ${targetUserId} does not exist.`
            );
        }

        const userData = userDoc.data();
        const fcmToken = userData?.fcmToken;

        if (!fcmToken) {
             throw new functions.https.HttpsError(
                "failed-precondition",
                `User with ID ${targetUserId} does not have a registered FCM token.`
            );
        }

        // 3. Use FCM Admin SDK to send
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

        return { success: true, messageId: response };

    } catch (error) {
        console.error("Error sending notification:", error);
        if (error instanceof functions.https.HttpsError) {
            throw error;
        }
        throw new functions.https.HttpsError(
            "internal",
            "Error sending notification",
            error
        );
    }
});
