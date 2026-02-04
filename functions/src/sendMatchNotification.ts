import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { getNotificationCopy } from "./notification_content";

if (admin.apps.length === 0) {
    admin.initializeApp();
}

export const sendMatchNotification = functions.https.onCall(async (data, context) => {
    // Auth check
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "The function must be called while authenticated."
        );
    }

    const { user1Id, user2Id, chatRoomId } = data;

    if (!user1Id || !user2Id || !chatRoomId) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Missing required parameters: user1Id, user2Id, chatRoomId."
        );
    }

    try {
        const db = admin.firestore();
        const user1Doc = await db.collection("users").doc(user1Id).get();
        const user2Doc = await db.collection("users").doc(user2Id).get();

        if (!user1Doc.exists || !user2Doc.exists) {
            throw new functions.https.HttpsError(
                "not-found",
                "One or both users not found."
            );
        }

        const user1Data = user1Doc.data();
        const user2Data = user2Doc.data();

        const user1Token = user1Data?.fcmToken;
        const user2Token = user2Data?.fcmToken;

        const messages: admin.messaging.Message[] = [];

        // Notify User 1
        if (user1Token) {
            const { title, body } = getNotificationCopy(
                "match_success_copy_v1",
                "control", // We could implement logic to fetch assigned variant
                { userName: user2Data?.name || "Someone" }
            );

            messages.push({
                token: user1Token,
                notification: { title, body },
                data: {
                    type: "match", // Use 'match' as per NotificationType enum mentioned in memory
                    actionType: "open_chat",
                    actionData: chatRoomId,
                    notificationId: `match_${chatRoomId}_${user1Id}`, // Unique ID
                    chatRoomId: chatRoomId, // For legacy or convenience
                },
            });
        }

        // Notify User 2
        if (user2Token) {
            const { title, body } = getNotificationCopy(
                "match_success_copy_v1",
                "control",
                { userName: user1Data?.name || "Someone" }
            );

            messages.push({
                token: user2Token,
                notification: { title, body },
                data: {
                    type: "match",
                    actionType: "open_chat",
                    actionData: chatRoomId,
                    notificationId: `match_${chatRoomId}_${user2Id}`,
                    chatRoomId: chatRoomId,
                },
            });
        }

        if (messages.length > 0) {
            await admin.messaging().sendEach(messages);
        }

        // Log stats (optional but good practice)
        await db.collection("notification_stats").add({
            type: "match_success",
            user1Id,
            user2Id,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            sentCount: messages.length,
        });

        return { success: true, sentCount: messages.length };

    } catch (error) {
        console.error("Error sending match notification:", error);
        throw new functions.https.HttpsError(
            "internal",
            "Failed to send match notifications.",
            error
        );
    }
});
