import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Initialize admin if not already initialized
if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Cloud Function to send a notification to a specific user.
 *
 * Arguments:
 * - targetUserId: string (The ID of the user to notify)
 * - title: string (Notification title)
 * - body: string (Notification body)
 * - data: object (Optional custom data)
 */
export const sendNotification = functions.https.onCall(async (data, context) => {
    // 1. Authentication check
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "The function must be called while authenticated."
        );
    }

    const { targetUserId, title, body, data: customData } = data;

    // 2. Validation
    if (!targetUserId || !title || !body) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "The function must be called with arguments 'targetUserId', 'title', and 'body'."
        );
    }

    try {
        // 3. Get target user's FCM token
        const userDoc = await admin.firestore().collection("users").doc(targetUserId).get();

        if (!userDoc.exists) {
            console.warn(`Target user ${targetUserId} not found.`);
            return { success: false, error: "User not found" };
        }

        const userData = userDoc.data();
        const fcmToken = userData?.fcmToken;

        if (!fcmToken) {
            console.log(`No FCM token for user ${targetUserId}`);
            // We return success: false but don't throw, as the user might just not have a token yet
            return { success: false, error: "No FCM token" };
        }

        // 4. Send notification
        const message = {
            notification: {
                title: title,
                body: body,
            },
            data: customData || {},
            token: fcmToken,
        };

        await admin.messaging().send(message);

        console.log(`Notification sent to user ${targetUserId}`);
        return { success: true };
    } catch (error) {
        console.error("Error sending notification:", error);
        throw new functions.https.HttpsError(
            "internal",
            "Unable to send notification",
            error
        );
    }
});
