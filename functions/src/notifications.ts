import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Ensure admin app is initialized only once
if (!admin.apps.length) {
    admin.initializeApp();
}

export const onMessageCreated = functions.firestore
    .document("messages/{messageId}")
    .onCreate(async (snapshot, context) => {
        const messageData = snapshot.data();
        if (!messageData) {
            console.log("No message data");
            return;
        }

        const { chatRoomId, senderId, senderName, message, text, type } = messageData;

        // Handle both standardized 'message' and legacy 'text' fields
        const rawContent = message || text || "";

        // Skip if empty message or system message
        if (!rawContent) {
             console.log("Empty message content");
             return;
        }

        try {
            // Get chat room details to find the other participant
            const chatRoomDoc = await admin.firestore()
                .collection("chat_rooms")
                .doc(chatRoomId)
                .get();

            if (!chatRoomDoc.exists) {
                console.log(`Chat room ${chatRoomId} does not exist`);
                return;
            }

            const chatRoomData = chatRoomDoc.data();
            const participantIds: string[] = chatRoomData?.participantIds || [];

            // Find recipient (someone who is NOT the sender)
            const recipientId = participantIds.find((id) => id !== senderId);

            if (!recipientId) {
                console.log("Recipient not found");
                return;
            }

            // Get recipient user data for FCM token and preferences
            const recipientDoc = await admin.firestore()
                .collection("users")
                .doc(recipientId)
                .get();

            if (!recipientDoc.exists) {
                console.log(`Recipient ${recipientId} does not exist`);
                return;
            }

            const recipientData = recipientDoc.data();
            const fcmToken = recipientData?.fcmToken;

            if (!fcmToken) {
                console.log(`No FCM token for user ${recipientId}`);
                return;
            }

            // Check notification preferences
            // Default to true if preferences are missing
            const notificationPreferences = recipientData?.notificationPreferences || {};
            const isNewMessageEnabled = notificationPreferences.newMessage !== false;

            if (!isNewMessageEnabled) {
                console.log(`User ${recipientId} has disabled new message notifications`);
                return;
            }

            // Fetch sender name if missing
            let finalSenderName = senderName;
            if (!finalSenderName) {
                 const senderDoc = await admin.firestore().collection("users").doc(senderId).get();
                 if (senderDoc.exists) {
                     finalSenderName = senderDoc.data()?.name;
                 }
            }
            finalSenderName = finalSenderName || "New Message";

            // Construct notification payload
            let preview = "";
            if (type && type !== "text") {
                if (type === "image") preview = "[Image]";
                else if (type === "gif") preview = "[GIF]";
                else if (type === "sticker") preview = "[Sticker]";
                else preview = `[${type}]`;
            } else {
                preview = rawContent.length > 20
                    ? `${rawContent.substring(0, 20)}...`
                    : rawContent;
            }

            const payload = {
                notification: {
                    title: finalSenderName,
                    body: preview,
                },
                data: {
                    type: "chat",
                    chatRoomId: chatRoomId,
                    senderId: senderId,
                    click_action: "FLUTTER_NOTIFICATION_CLICK",
                },
                token: fcmToken,
            };

            // Send message
            await admin.messaging().send(payload);
            console.log(`Notification sent to ${recipientId} for message ${context.params.messageId}`);

        } catch (error) {
            console.error("Error sending chat notification:", error);
        }
    });
