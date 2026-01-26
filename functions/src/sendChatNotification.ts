import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Cloud Function for sending chat notifications
 * Called by ChatService when a new message is sent
 */
export const sendChatNotification = functions.https.onCall(async (data, context) => {
    // 1. Verify authentication
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "Only authenticated users can send chat notifications."
        );
    }

    const { chatRoomId, senderName, messagePreview, senderId } = data;

    // Validate required fields
    if (!chatRoomId || !senderName || !messagePreview || !senderId) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Missing required fields: chatRoomId, senderName, messagePreview, senderId."
        );
    }

    try {
        // 2. Fetch Chat Room to identify recipient
        const chatRoomDoc = await admin.firestore().collection("chat_rooms").doc(chatRoomId).get();
        if (!chatRoomDoc.exists) {
            throw new functions.https.HttpsError("not-found", "Chat room not found.");
        }

        const chatRoomData = chatRoomDoc.data();
        const participantIds: string[] = chatRoomData?.participantIds || [];

        // Find recipient (the one who is NOT the sender)
        const recipientId = participantIds.find((id) => id !== senderId);

        if (!recipientId) {
            console.log("No recipient found in chat room:", chatRoomId);
            return { success: false, message: "No recipient found" };
        }

        // 3. Fetch Recipient's FCM Token
        const userDoc = await admin.firestore().collection("users").doc(recipientId).get();
        if (!userDoc.exists) {
            console.log("Recipient user not found:", recipientId);
            return { success: false, message: "Recipient user not found" };
        }

        const userData = userDoc.data();
        const fcmToken = userData?.fcmToken;

        if (!fcmToken) {
            console.log("Recipient has no FCM token:", recipientId);
            return { success: false, message: "Recipient has no FCM token" };
        }

        // 4. Send Notification
        const message = {
            notification: {
                title: senderName,
                body: messagePreview,
            },
            data: {
                type: "chat",
                chatRoomId: chatRoomId,
                senderId: senderId,
                click_action: "FLUTTER_NOTIFICATION_CLICK",
            },
            token: fcmToken,
        };

        const response = await admin.messaging().send(message);
        console.log("Successfully sent chat notification:", response);

        return { success: true, messageId: response };

    } catch (error) {
        console.error("Error sending chat notification:", error);
        throw new functions.https.HttpsError(
            "internal",
            "Failed to send chat notification.",
            error
        );
    }
});
