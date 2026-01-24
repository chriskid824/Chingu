import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
    admin.initializeApp();
}

export const sendChatNotification = functions.https.onCall(async (data, context) => {
    // Check auth
    if (!context.auth) {
            throw new functions.https.HttpsError(
            "unauthenticated",
            "User must be authenticated to send notifications."
        );
    }
    const { recipientId, senderName, messageText } = data;

    // Fetch recipient's FCM token
    const userDoc = await admin.firestore().collection("users").doc(recipientId).get();
    const fcmToken = userDoc.data()?.fcmToken;

    if (fcmToken) {
        await admin.messaging().send({
            token: fcmToken,
            notification: {
                title: senderName,
                body: messageText,
            },
            data: {
                type: 'chat_message',
                senderId: context.auth.uid,
                click_action: 'FLUTTER_NOTIFICATION_CLICK'
            }
        });
        return { success: true };
    } else {
        console.log(`No FCM token found for user ${recipientId}`);
        return { success: false, reason: "no_token" };
    }
});
