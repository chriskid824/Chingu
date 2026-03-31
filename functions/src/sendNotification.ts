import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
    admin.initializeApp();
}

interface SendNotificationData {
    targetUserId: string;
    title: string;
    body: string;
    imageUrl?: string;
    data?: { [key: string]: string };
}

export const sendNotification = functions.https.onCall(async (data: SendNotificationData, context) => {
    // 1. Authenticate User
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "The function must be called while authenticated."
        );
    }

    const { targetUserId, title, body, imageUrl, data: customData } = data;

    // Validate inputs
    if (!targetUserId || !title || !body) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "The function must be called with 'targetUserId', 'title', and 'body'."
        );
    }

    try {
        // 2. Get Target User FCM Token
        const userDoc = await admin.firestore().collection("users").doc(targetUserId).get();

        if (!userDoc.exists) {
            throw new functions.https.HttpsError(
                "not-found",
                `User with ID ${targetUserId} not found.`
            );
        }

        const userData = userDoc.data();
        const fcmToken = userData?.fcmToken;

        if (!fcmToken) {
            throw new functions.https.HttpsError(
                "failed-precondition",
                "The user has no registered FCM token."
            );
        }

        // 3. Send Notification
        const message: admin.messaging.Message = {
            token: fcmToken,
            notification: {
                title,
                body,
                ...(imageUrl && { imageUrl }),
            },
            data: customData || {},
        };

        const response = await admin.messaging().send(message);

        // Log the notification
        await admin.firestore().collection("notification_logs").add({
            senderId: context.auth.uid,
            targetUserId,
            title,
            body,
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
            messageId: response,
            type: "direct_notification"
        });

        return { success: true, messageId: response };

    } catch (error) {
        console.error("Error sending notification:", error);
        if (error instanceof functions.https.HttpsError) {
            throw error;
        }
        throw new functions.https.HttpsError(
            "internal",
            "Unable to send notification",
            error
        );
    }
});
