import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Interface for NotificationPreferences (matching Dart model)
interface NotificationPreferences {
    enablePush: boolean;
    newMatch: boolean;
    matchSuccess: boolean;
    newMessage: boolean;
    eventReminder: boolean;
    eventChange: boolean;
    promotions: boolean;
    newsletter: boolean;
}

// Default preferences
const defaultPreferences: NotificationPreferences = {
    enablePush: true,
    newMatch: true,
    matchSuccess: true,
    newMessage: true,
    eventReminder: true,
    eventChange: true,
    promotions: false,
    newsletter: false,
};

// Helper to get user preferences
async function getUserNotificationPreferences(userId: string): Promise<NotificationPreferences> {
    const userDoc = await admin.firestore().collection("users").doc(userId).get();
    if (!userDoc.exists) return defaultPreferences;

    const data = userDoc.data();
    if (!data || !data.notificationPreferences) return defaultPreferences;

    return { ...defaultPreferences, ...data.notificationPreferences };
}

// Helper to send FCM
async function sendFCM(userId: string, title: string, body: string, data?: Record<string, string>) {
    try {
        const userDoc = await admin.firestore().collection("users").doc(userId).get();
        const token = userDoc.data()?.fcmToken;

        if (!token) {
            console.log(`No FCM token for user ${userId}`);
            return;
        }

        const message = {
            notification: {
                title,
                body,
            },
            data: data || {},
            token: token,
        };

        await admin.messaging().send(message);
        console.log(`Notification sent to ${userId}`);
    } catch (e) {
        console.error(`Error sending notification to ${userId}:`, e);
    }
}

export const onSwipeCreated = functions.firestore
    .document("swipes/{swipeId}")
    .onCreate(async (snap, context) => {
        const swipe = snap.data();
        if (!swipe || !swipe.isLike) return;

        const userId = swipe.userId;
        const targetUserId = swipe.targetUserId;

        // Check target user's preferences
        const prefs = await getUserNotificationPreferences(targetUserId);

        if (!prefs.enablePush || !prefs.newMatch) {
            console.log(`User ${targetUserId} has disabled new match notifications.`);
            return;
        }

        // Get liker's name
        const likerDoc = await admin.firestore().collection("users").doc(userId).get();
        const likerName = likerDoc.data()?.name || "Someone";

        await sendFCM(
            targetUserId,
            "New Like!",
            `${likerName} liked you!`,
            { type: "new_match", userId: userId }
        );
    });

export const onChatRoomCreated = functions.firestore
    .document("chat_rooms/{roomId}")
    .onCreate(async (snap, context) => {
        const chatRoom = snap.data();
        if (!chatRoom) return;

        const participantIds = chatRoom.participantIds as string[];
        if (!participantIds || participantIds.length !== 2) return;

        const user1Id = participantIds[0];
        const user2Id = participantIds[1];

        // Notify User 1
        const prefs1 = await getUserNotificationPreferences(user1Id);
        if (prefs1.enablePush && prefs1.matchSuccess) {
            // Get User 2 name
            const user2Doc = await admin.firestore().collection("users").doc(user2Id).get();
            const user2Name = user2Doc.data()?.name || "Someone";

            await sendFCM(
                user1Id,
                "It's a Match!",
                `You matched with ${user2Name}!`,
                { type: "match_success", chatRoomId: context.params.roomId }
            );
        }

        // Notify User 2
        const prefs2 = await getUserNotificationPreferences(user2Id);
        if (prefs2.enablePush && prefs2.matchSuccess) {
            // Get User 1 name
            const user1Doc = await admin.firestore().collection("users").doc(user1Id).get();
            const user1Name = user1Doc.data()?.name || "Someone";

            await sendFCM(
                user2Id,
                "It's a Match!",
                `You matched with ${user1Name}!`,
                { type: "match_success", chatRoomId: context.params.roomId }
            );
        }
    });

export const onMessageCreated = functions.firestore
    .document("messages/{messageId}")
    .onCreate(async (snap, context) => {
        const message = snap.data();
        if (!message) return;

        const chatRoomId = message.chatRoomId;
        const senderId = message.senderId;
        const text = message.text || message.message || "New message"; // Handle both formats

        if (!chatRoomId || !senderId) return;

        // Get chat room to find recipient
        const chatRoomDoc = await admin.firestore().collection("chat_rooms").doc(chatRoomId).get();
        if (!chatRoomDoc.exists) return;

        const chatRoomData = chatRoomDoc.data();
        const participantIds = chatRoomData?.participantIds as string[];

        if (!participantIds) return;

        const recipientId = participantIds.find((id) => id !== senderId);
        if (!recipientId) return;

        // Check recipient preferences
        const prefs = await getUserNotificationPreferences(recipientId);
        if (!prefs.enablePush || !prefs.newMessage) {
            console.log(`User ${recipientId} has disabled new message notifications.`);
            return;
        }

        // Get sender name
        const senderName = message.senderName || chatRoomData?.participantData?.[senderId]?.name || "Someone";

        await sendFCM(
            recipientId,
            senderName,
            text,
            { type: "new_message", chatRoomId: chatRoomId, messageId: context.params.messageId }
        );
    });
