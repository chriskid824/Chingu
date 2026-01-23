import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Sends a push notification to the other participant in a chat room.
 *
 * Data:
 * - chatRoomId: string
 * - senderName: string
 * - messageBody: string
 */
export const sendChatNotification = functions.https.onCall(async (data, context) => {
    // 1. Authenticate
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "Only authenticated users can send chat notifications."
        );
    }

    const { chatRoomId, senderName, messageBody } = data;

    if (!chatRoomId || !senderName || !messageBody) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Missing chatRoomId, senderName, or messageBody."
        );
    }

    const senderId = context.auth.uid;

    try {
        // 2. Get Chat Room
        const chatRoomDoc = await admin.firestore().collection("chat_rooms").doc(chatRoomId).get();
        if (!chatRoomDoc.exists) {
            throw new functions.https.HttpsError("not-found", "Chat room not found.");
        }

        const chatRoomData = chatRoomDoc.data();
        const participants = (chatRoomData?.participantIds || []) as string[];

        // Security Check: Ensure sender is a participant
        if (!participants.includes(senderId)) {
            throw new functions.https.HttpsError(
                "permission-denied",
                "You are not a participant of this chat room."
            );
        }

        // 3. Find recipient
        const recipientId = participants.find((uid) => uid !== senderId);
        if (!recipientId) {
             console.log("No recipient found in chat room.");
             return { success: false, reason: "No recipient found" };
        }

        // 4. Get Recipient Token
        const recipientDoc = await admin.firestore().collection("users").doc(recipientId).get();
        if (!recipientDoc.exists) {
             console.log("Recipient user doc not found.");
             return { success: false, reason: "Recipient not found" };
        }

        const recipientData = recipientDoc.data();
        const fcmToken = recipientData?.fcmToken;

        if (!fcmToken) {
            console.log(`Recipient ${recipientId} has no FCM token.`);
            return { success: false, reason: "No FCM token" };
        }

        // 5. Send Notification
        // Truncate message to 20 chars
        const preview = messageBody.length > 20 ? messageBody.substring(0, 20) + "..." : messageBody;

        const message = {
            notification: {
                title: senderName,
                body: preview,
            },
            data: {
                actionType: "open_chat",
                actionData: chatRoomId,
                type: "message",
                senderId: senderId,
            },
            token: fcmToken,
        };

        await admin.messaging().send(message);

        return { success: true };

    } catch (error) {
        console.error("Error sending chat notification:", error);
        throw new functions.https.HttpsError("internal", "Failed to send notification", error);
    }
});
