import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
    admin.initializeApp();
}

export const sendChatNotification = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "The function must be called while authenticated."
        );
    }

    const { recipientId, senderName, message } = data;

    if (!recipientId || !senderName || !message) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "The function must be called with recipientId, senderName, and message."
        );
    }

    try {
        const userDoc = await admin.firestore().collection("users").doc(recipientId).get();
        const userData = userDoc.data();

        if (!userData || !userData.fcmToken) {
            console.log(`No FCM token found for user ${recipientId}`);
            return { success: false, message: "No FCM token found for user." };
        }

        const fcmToken = userData.fcmToken;

        const notificationMessage = {
            notification: {
                title: senderName,
                body: message,
            },
            data: {
                click_action: "FLUTTER_NOTIFICATION_CLICK",
                type: "chat_message",
                senderName: senderName,
                message: message,
            },
            token: fcmToken,
        };

        await admin.messaging().send(notificationMessage);

        return { success: true };
    } catch (error) {
        console.error("Error sending chat notification:", error);
        throw new functions.https.HttpsError(
            "internal",
            "Unable to send notification"
        );
    }
});
