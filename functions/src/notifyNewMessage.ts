import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { newMessageTest, getNotificationCopy } from "./notification_content";

// Initialize admin if not already initialized
if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Cloud Function triggered when a new message is created in the 'messages' collection.
 * Sends a push notification to the recipient.
 */
export const notifyNewMessage = functions.firestore
    .document("messages/{messageId}")
    .onCreate(async (snapshot, context) => {
        const messageData = snapshot.data();
        if (!messageData) {
            console.error("Message data is empty");
            return;
        }

        const {
            chatRoomId,
            senderId,
            senderName: messageSenderName,
            text, // ChatProvider uses 'text'
            message, // ChatService uses 'message'
            recipientId: messageRecipientId,
        } = messageData;

        // Determine message content (support both fields)
        const messageContent = text || message || "Sent an image";
        const messagePreview = messageContent.length > 20
            ? messageContent.substring(0, 20) + "..."
            : messageContent;

        try {
            let recipientId = messageRecipientId;
            let senderName = messageSenderName;

            // 1. If recipientId is missing, fetch it from chatRoom
            if (!recipientId) {
                console.log(`Recipient ID missing in message ${context.params.messageId}, fetching chat room...`);
                const chatRoomDoc = await admin.firestore().collection("chat_rooms").doc(chatRoomId).get();
                if (!chatRoomDoc.exists) {
                    console.error(`Chat room ${chatRoomId} not found`);
                    return;
                }

                const chatRoomData = chatRoomDoc.data();
                const participantIds = chatRoomData?.participantIds || [];
                recipientId = participantIds.find((id: string) => id !== senderId);
            }

            if (!recipientId) {
                console.error("Could not determine recipient ID");
                return;
            }

            // 2. If senderName is missing, fetch it from sender's user doc
            if (!senderName) {
                console.log(`Sender Name missing in message ${context.params.messageId}, fetching sender...`);
                const senderDoc = await admin.firestore().collection("users").doc(senderId).get();
                if (senderDoc.exists) {
                    senderName = senderDoc.data()?.name || "Someone";
                } else {
                    senderName = "Someone";
                }
            }

            // 3. Get recipient's FCM token
            const recipientDoc = await admin.firestore().collection("users").doc(recipientId).get();
            if (!recipientDoc.exists) {
                console.error(`Recipient ${recipientId} not found`);
                return;
            }

            const fcmToken = recipientDoc.data()?.fcmToken;
            if (!fcmToken) {
                console.log(`Recipient ${recipientId} has no FCM token`);
                return;
            }

            // 4. Determine notification content
            // We use 'control' variant for now to ensure consistent behavior as requested.
            // {userName} 傳來訊息
            // {messagePreview}
            const notificationContent = getNotificationCopy(
                newMessageTest.testId,
                'control',
                {
                    userName: senderName,
                    messagePreview: messagePreview,
                }
            );

            // 5. Send Notification
            const payload = {
                notification: {
                    title: notificationContent.title,
                    body: notificationContent.body,
                },
                data: {
                    type: "message",
                    actionType: "open_chat",
                    actionData: chatRoomId,
                    senderId: senderId,
                    click_action: "FLUTTER_NOTIFICATION_CLICK",
                },
                token: fcmToken,
            };

            await admin.messaging().send(payload);
            console.log(`Notification sent to ${recipientId}`);

        } catch (error) {
            console.error("Error sending notification:", error);
        }
    });
