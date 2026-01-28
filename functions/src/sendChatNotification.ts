import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
    admin.initializeApp();
}

export const sendChatNotification = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "The function must be called while authenticated."
        );
    }

    const { chatRoomId, senderId, senderName, message } = data;

    if (context.auth.uid !== senderId) {
        throw new functions.https.HttpsError(
            "permission-denied",
            "Sender ID must match authenticated user."
        );
    }

    if (!chatRoomId || !senderId || !senderName || !message) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Missing required arguments: chatRoomId, senderId, senderName, message."
        );
    }

    try {
        const chatRoomDoc = await admin.firestore().collection('chat_rooms').doc(chatRoomId).get();
        if (!chatRoomDoc.exists) {
             throw new functions.https.HttpsError("not-found", "Chat room not found.");
        }

        const roomData = chatRoomDoc.data();
        const participantIds = roomData?.participantIds || [];

        // Security check: Ensure sender is part of the chat room
        if (!participantIds.includes(senderId)) {
             throw new functions.https.HttpsError("permission-denied", "User is not a participant in this chat room.");
        }

        const recipientId = participantIds.find((id: string) => id !== senderId);
        if (!recipientId) {
             console.log("No recipient found (maybe self-chat or empty).");
             return { success: false, message: "No recipient found." };
        }

        const userDoc = await admin.firestore().collection('users').doc(recipientId).get();
        if (!userDoc.exists) {
            console.log("Recipient user doc not found.");
            return { success: false, message: "Recipient not found." };
        }

        const fcmToken = userDoc.data()?.fcmToken;
        if (!fcmToken) {
            console.log("Recipient has no FCM token.");
            return { success: false, message: "Recipient has no FCM token." };
        }

        // Truncate message to 20 chars
        const preview = message.length > 20 ? message.substring(0, 20) + "..." : message;

        const payload = {
            notification: {
                title: senderName,
                body: preview,
            },
            data: {
                actionType: 'open_chat',
                actionData: chatRoomId,
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
                type: 'chat',
            },
            token: fcmToken,
        };

        const response = await admin.messaging().send(payload);
        console.log("Successfully sent chat notification:", response);

        return { success: true, messageId: response };

    } catch (error) {
        console.error("Error sending chat notification:", error);
        throw new functions.https.HttpsError("internal", "Unable to send notification", error);
    }
});
