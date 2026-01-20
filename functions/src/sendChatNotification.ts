import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (!admin.apps.length) {
  admin.initializeApp();
}

/**
 * Cloud Function to send chat push notifications.
 *
 * @param data.recipientId The UID of the user to receive the notification.
 * @param data.senderName The display name of the sender.
 * @param data.messageContent The content of the message.
 * @param data.chatRoomId The ID of the chat room (for navigation/deeplinking).
 */
export const sendChatNotification = functions.https.onCall(async (data, context) => {
  // 1. Authentication Check
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "The function must be called while authenticated."
    );
  }

  const {recipientId, senderName, messageContent, chatRoomId} = data;

  // 2. Input Validation
  if (!recipientId || !senderName || !messageContent || !chatRoomId) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "The function must be called with argument 'recipientId', 'senderName', 'messageContent' and 'chatRoomId'."
    );
  }

  try {
    // 3. Get Recipient's FCM Token
    const userDoc = await admin.firestore().collection("users").doc(recipientId).get();
    if (!userDoc.exists) {
        console.log(`User ${recipientId} not found, skipping notification.`);
        return {success: false, message: "User not found"};
    }

    const userData = userDoc.data();
    const fcmToken = userData?.fcmToken;

    if (!fcmToken) {
      console.log(`User ${recipientId} has no FCM token, skipping notification.`);
      return {success: false, message: "User has no FCM token"};
    }

    // 4. Construct Notification Payload
    // Limit preview to 20 characters
    const preview = messageContent.length > 20 ?
        messageContent.substring(0, 20) + "..." :
        messageContent;

    const message = {
      token: fcmToken,
      notification: {
        title: senderName,
        body: preview,
      },
      data: {
        type: "chat_message",
        chatRoomId: chatRoomId,
        senderName: senderName,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      android: {
        priority: "high" as const, // Fix for TypeScript enum/type mismatch if needed
        notification: {
          channelId: "high_importance_channel",
        },
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title: senderName,
              body: preview,
            },
            sound: "default",
            badge: 1,
          },
        },
      },
    };

    // 5. Send Notification
    await admin.messaging().send(message);
    console.log(`Chat notification sent to ${recipientId}`);

    return {success: true};
  } catch (error) {
    console.error("Error sending chat notification:", error);
    throw new functions.https.HttpsError(
        "internal",
        "Unable to send notification",
        error
    );
  }
});
