import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

/**
 * Cloud Function for sending chat notifications
 * Called when a user sends a message in a chat room
 */
export const sendChatNotification = functions.https.onCall(async (data, context) => {
    // Verify authentication
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "The function must be called while authenticated."
        );
    }

    const { recipientId, senderName, message, chatRoomId } = data;

    // Validate required fields
    if (!recipientId || !senderName || !message || !chatRoomId) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Missing required fields: recipientId, senderName, message, chatRoomId."
        );
    }

    try {
        // Fetch recipient's FCM token
        const userDoc = await admin.firestore().collection("users").doc(recipientId).get();

        if (!userDoc.exists) {
            console.log(`Recipient ${recipientId} not found`);
            return { success: false, error: "Recipient not found" };
        }

        const userData = userDoc.data();
        const fcmToken = userData?.fcmToken;

        if (!fcmToken) {
            console.log(`No FCM token for user ${recipientId}`);
            return { success: false, error: "No FCM token found" };
        }

        // Send notification
        const payload = {
            notification: {
                title: senderName,
                body: message,
            },
            data: {
                click_action: "FLUTTER_NOTIFICATION_CLICK",
                type: "chat",
                chatRoomId: chatRoomId,
            },
            token: fcmToken,
        };

        const response = await admin.messaging().send(payload);
        console.log("Successfully sent message:", response);

        return { success: true, messageId: response };
    } catch (error) {
        console.error("Error sending chat notification:", error);
        throw new functions.https.HttpsError(
            "internal",
            "Failed to send notification",
            error
        );
    }
});
