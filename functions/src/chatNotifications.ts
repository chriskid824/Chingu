import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { newMessageTest, getNotificationCopy } from "./notification_content";

/**
 * Sends a chat notification to the other participant(s) in a chat room.
 *
 * Expected data:
 * - message: string
 * - chatRoomId: string
 */
export const sendChatNotification = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "The function must be called while authenticated."
        );
    }

    const { message, chatRoomId } = data;

    if (!message || !chatRoomId) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Missing required arguments: message, chatRoomId."
        );
    }

    try {
        const firestore = admin.firestore();
        const senderId = context.auth.uid;

        // 1. Fetch Chat Room and Verify Sender
        const chatRoomDoc = await firestore.collection("chat_rooms").doc(chatRoomId).get();
        if (!chatRoomDoc.exists) {
            throw new functions.https.HttpsError(
                "not-found",
                "Chat room not found."
            );
        }

        const chatRoomData = chatRoomDoc.data();
        const participantIds: string[] = chatRoomData?.participantIds || [];

        if (!participantIds.includes(senderId)) {
            throw new functions.https.HttpsError(
                "permission-denied",
                "You are not a participant of this chat room."
            );
        }

        // 2. Identify Recipients
        const recipientIds = participantIds.filter((id) => id !== senderId);

        if (recipientIds.length === 0) {
            console.log("No other participants to notify.");
            return { success: true, message: "No recipients found." };
        }

        // 3. Get Sender's Name
        const senderDoc = await firestore.collection("users").doc(senderId).get();
        const senderName = senderDoc.data()?.name || "Someone";

        // 4. Prepare Notification Content
        const variantId = newMessageTest.defaultVariantId;
        const { title, body } = getNotificationCopy(newMessageTest.testId, variantId, {
            userName: senderName,
            messagePreview: message,
        });

        // 5. Send to each recipient
        const promises = recipientIds.map(async (recipientId) => {
            try {
                const userDoc = await firestore.collection("users").doc(recipientId).get();
                const fcmToken = userDoc.data()?.fcmToken;

                if (!fcmToken) {
                    console.log(`User ${recipientId} has no FCM token.`);
                    return;
                }

                const notificationMessage = {
                    notification: {
                        title: title,
                        body: body,
                    },
                    data: {
                        actionType: "open_chat",
                        actionData: chatRoomId,
                        senderId: senderId,
                        chatRoomId: chatRoomId,
                    },
                    token: fcmToken,
                };

                await admin.messaging().send(notificationMessage);
                console.log(`Notification sent to ${recipientId}`);
            } catch (err) {
                console.error(`Failed to send notification to ${recipientId}:`, err);
            }
        });

        await Promise.all(promises);

        return { success: true };
    } catch (error) {
        console.error("Error sending chat notification:", error);
        if (error instanceof functions.https.HttpsError) {
            throw error;
        }
        throw new functions.https.HttpsError(
            "internal",
            "Unable to send notification",
            error
        );
    }
});
