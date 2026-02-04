import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

/**
 * Sends a push notification for a new chat message.
 *
 * Expected data:
 * - chatRoomId: string
 * - messageBody: string
 */
export const sendChatNotification = functions.https.onCall(async (data, context) => {
  // Check authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  const { chatRoomId, messageBody } = data;
  const senderId = context.auth.uid;

  if (!chatRoomId || !messageBody) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Missing required arguments: chatRoomId, messageBody."
    );
  }

  try {
    const chatRoomDoc = await admin.firestore().collection("chat_rooms").doc(chatRoomId).get();

    if (!chatRoomDoc.exists) {
        throw new functions.https.HttpsError("not-found", "Chat room not found");
    }

    const chatData = chatRoomDoc.data();
    const participantIds: string[] = chatData?.participantIds || [];

    if (!participantIds.includes(senderId)) {
        throw new functions.https.HttpsError("permission-denied", "User is not a participant in this chat room");
    }

    const recipientId = participantIds.find((id) => id !== senderId);

    if (!recipientId) {
         console.log(`No recipient found in chat room ${chatRoomId}`);
         return { success: false, error: "No recipient found" };
    }

    // Get sender name
    // Try to get from participantData first
    let senderName = "User";
    if (chatData?.participantData && chatData.participantData[senderId]) {
        senderName = chatData.participantData[senderId].name || "User";
    } else {
        // Fallback to fetching user doc
        const senderDoc = await admin.firestore().collection("users").doc(senderId).get();
        if (senderDoc.exists) {
            senderName = senderDoc.data()?.name || "User";
        }
    }

    // Get recipient token
    const userDoc = await admin.firestore().collection("users").doc(recipientId).get();

    if (!userDoc.exists) {
        console.log(`User ${recipientId} does not exist`);
        return { success: false, error: "Recipient user not found" };
    }

    const userData = userDoc.data();
    const fcmToken = userData?.fcmToken;

    if (!fcmToken) {
        console.log(`User ${recipientId} does not have an FCM token`);
        return { success: false, error: "No FCM token" };
    }

    // Truncate message body to 20 chars
    const truncatedBody = messageBody.length > 20 ? messageBody.substring(0, 20) + "..." : messageBody;

    const message = {
      token: fcmToken,
      notification: {
        title: senderName,
        body: truncatedBody,
      },
      data: {
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        type: "chat",
        senderName: senderName,
        chatRoomId: chatRoomId,
      },
    };

    await admin.messaging().send(message);
    return { success: true };

  } catch (error) {
    console.error("Error sending chat notification:", error);
    if (error instanceof functions.https.HttpsError) {
        throw error;
    }
    throw new functions.https.HttpsError("internal", "Unable to send notification");
  }
});
