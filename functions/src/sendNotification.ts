import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Cloud Function for sending chat notifications
 * Can be called by authenticated users to send a notification to a chat recipient
 *
 * Data Params:
 * - chatRoomId: string
 * - senderId: string
 * - senderName: string
 * - message: string
 */
export const sendNotification = functions.https.onCall(async (data, context) => {
    // 1. Auth check
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "The function must be called while authenticated."
        );
    }

    const { chatRoomId, senderId, senderName, message } = data;

    // 2. Validate input
    if (!chatRoomId || !senderId || !senderName || !message) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "The function must be called with arguments: chatRoomId, senderId, senderName, message."
        );
    }

    // Verify sender matches auth (optional security check)
    if (context.auth.uid !== senderId) {
        throw new functions.https.HttpsError(
            "permission-denied",
            "Sender ID does not match authenticated user."
        );
    }

    try {
        // 3. Get chat room to find recipient
        const chatRoomDoc = await admin.firestore().collection("chat_rooms").doc(chatRoomId).get();
        if (!chatRoomDoc.exists) {
            throw new functions.https.HttpsError("not-found", "Chat room not found");
        }

        const chatData = chatRoomDoc.data();
        const participants: string[] = chatData?.participantIds || [];

        // Find recipient (the one who is not the sender)
        const recipientId = participants.find(id => id !== senderId);

        if (!recipientId) {
            console.log(`No recipient found for chat room ${chatRoomId} and sender ${senderId}`);
            // This might happen if user talks to themselves or data is corrupted.
            // We treat it as success (no notification sent) to not break the client.
            return { success: false, reason: "No recipient found" };
        }

        // 4. Get recipient FCM token
        const userDoc = await admin.firestore().collection("users").doc(recipientId).get();
        if (!userDoc.exists) {
            console.log(`User ${recipientId} not found`);
            return { success: false, reason: "Recipient user not found" };
        }

        const userData = userDoc.data();
        const fcmToken = userData?.fcmToken;

        if (!fcmToken) {
            console.log(`No FCM token for user ${recipientId}`);
            return { success: false, reason: "No FCM token" };
        }

        // 5. Construct message
        // Preview: first 20 chars
        const preview = message.length > 20 ? message.substring(0, 20) + "..." : message;

        const payload = {
            token: fcmToken,
            notification: {
                title: senderName,
                body: preview,
            },
            data: {
                type: "chat",
                chatRoomId: chatRoomId,
                senderId: senderId,
                click_action: "FLUTTER_NOTIFICATION_CLICK",
            }
        };

        // 6. Send
        await admin.messaging().send(payload);

        // Log the notification event
        await admin.firestore().collection("notification_events").add({
            type: "chat_message",
            senderId: senderId,
            recipientId: recipientId,
            chatRoomId: chatRoomId,
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
            status: "sent"
        });

        return { success: true };

    } catch (error) {
        console.error("Error sending notification:", error);
        throw new functions.https.HttpsError("internal", "Error sending notification");
    }
});
