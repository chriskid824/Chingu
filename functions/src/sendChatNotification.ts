import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Ensure admin is initialized
if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Cloud Function triggered when a new message is added to the 'messages' collection.
 * It checks the recipient's notification settings and sends a push notification if enabled.
 */
export const sendChatNotification = functions.firestore
    .document("messages/{messageId}")
    .onCreate(async (snapshot, context) => {
        const messageData = snapshot.data();
        if (!messageData) {
            console.log("No message data");
            return;
        }

        const { chatRoomId, senderId, senderName, message, type } = messageData;

        // 1. Get Chat Room to find recipient
        const chatRoomSnapshot = await admin.firestore()
            .collection("chat_rooms")
            .doc(chatRoomId)
            .get();

        if (!chatRoomSnapshot.exists) {
            console.log("Chat room not found:", chatRoomId);
            return;
        }

        const chatRoomData = chatRoomSnapshot.data();
        const participantIds: string[] = chatRoomData?.participantIds || [];

        // Find recipient (someone who is not the sender)
        // Assuming 1-on-1 chat for now
        const recipientId = participantIds.find((id) => id !== senderId);

        if (!recipientId) {
            console.log("Recipient not found in chat room:", chatRoomId);
            return;
        }

        // 2. Get Recipient User Data for Settings and Token
        const recipientSnapshot = await admin.firestore()
            .collection("users")
            .doc(recipientId)
            .get();

        if (!recipientSnapshot.exists) {
            console.log("Recipient user not found:", recipientId);
            return;
        }

        const recipientData = recipientSnapshot.data();
        if (!recipientData) return;

        // 3. Check Notification Settings
        const settings = recipientData.notificationSettings || {};

        // Defaults to true if undefined
        const enablePush = settings.enablePushNotifications !== false;
        const enableNewMessage = settings.newMessage !== false;

        if (!enablePush || !enableNewMessage) {
            console.log(`Notification suppressed for user ${recipientId}. Settings: Push=${enablePush}, Chat=${enableNewMessage}`);
            return;
        }

        const fcmToken = recipientData.fcmToken;
        if (!fcmToken) {
            console.log("No FCM token for user:", recipientId);
            return;
        }

        // 4. Send Notification
        const notificationTitle = senderName || "New Message";
        let notificationBody = message || "You have a new message";

        if (type !== "text") {
            notificationBody = `[${type}]`;
        }

        const payload = {
            notification: {
                title: notificationTitle,
                body: notificationBody,
            },
            data: {
                click_action: "FLUTTER_NOTIFICATION_CLICK",
                type: "chat_message",
                chatRoomId: chatRoomId,
                senderId: senderId,
            },
            token: fcmToken,
        };

        try {
            await admin.messaging().send(payload);
            console.log("Chat notification sent to:", recipientId);
        } catch (error) {
            console.error("Error sending chat notification:", error);
        }
    });
