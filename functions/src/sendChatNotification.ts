import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Prevent re-initialization error
if (admin.apps.length === 0) {
  admin.initializeApp();
}

/**
 * Triggers when a new message is created in the messages collection.
 * Sends a push notification to the recipient.
 */
export const sendChatNotification = functions.firestore
    .document("messages/{messageId}")
    .onCreate(async (snapshot, context) => {
      const messageData = snapshot.data();
      const chatRoomId = messageData.chatRoomId;
      const senderId = messageData.senderId;
      const senderName = messageData.senderName || "Someone";
      const messageText = messageData.message || "";
      const messageType = messageData.type || "text";

      try {
        // 1. Get chat room data to find participants
        const chatRoomRef = admin.firestore().collection("chat_rooms").doc(chatRoomId);
        const chatRoomDoc = await chatRoomRef.get();

        if (!chatRoomDoc.exists) {
          console.error(`Chat room ${chatRoomId} not found`);
          return;
        }

        const chatRoomData = chatRoomDoc.data();
        const participants = chatRoomData?.participantIds || [];

        // 2. Identify recipient (the one who is not sender)
        const recipientId = participants.find((uid: string) => uid !== senderId);

        if (!recipientId) {
          console.error("No recipient found in chat room");
          return;
        }

        // 3. Get recipient's user data to get FCM token
        const userDoc = await admin.firestore().collection("users").doc(recipientId).get();

        if (!userDoc.exists) {
          console.error(`User ${recipientId} not found`);
          return;
        }

        const userData = userDoc.data();
        const fcmToken = userData?.fcmToken;

        if (!fcmToken) {
          console.log(`User ${recipientId} has no FCM token`);
          return;
        }

        // 4. Check notification settings if they exist
        const settings = userData?.notificationSettings;
        if (settings && settings.newMessage === false) {
          console.log(`User ${recipientId} has disabled message notifications`);
          return;
        }

        // 5. Construct notification content
        let bodyText = messageText;
        if (messageType === "image") {
          bodyText = "📷 [圖片]";
        } else if (messageType === "sticker") {
          bodyText = "😊 [貼圖]";
        }

        // Truncate to 20 chars
        if (bodyText.length > 20) {
          bodyText = bodyText.substring(0, 20) + "...";
        }

        const payload: admin.messaging.MessagingPayload = {
          notification: {
            title: senderName,
            body: bodyText,
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
          },
          data: {
            type: "message",
            chatRoomId: chatRoomId,
            senderId: senderId,
            senderName: senderName,
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          },
        };

        // 6. Send notification
        // Using sendToDevice for simplicity as it handles token strings directly
        await admin.messaging().sendToDevice(fcmToken, payload);
        console.log(`Notification sent to ${recipientId}`);
      } catch (error) {
        console.error("Error sending chat notification:", error);
      }
    });
