import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Ensure firebase-admin is initialized (it might be initialized in index.ts or other files, but safe to call if check)
if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Cloud Function to notify users of a successful match
 *
 * Arguments:
 * - user1Id: string
 * - user2Id: string
 * - chatRoomId: string
 */
export const notifyMatch = functions.https.onCall(async (data, context) => {
    // 1. Authentication check
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "Only authenticated users can trigger match notifications."
        );
    }

    const { user1Id, user2Id, chatRoomId } = data;

    if (!user1Id || !user2Id || !chatRoomId) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Missing required arguments: user1Id, user2Id, chatRoomId"
        );
    }

    try {
        // 2. Fetch user data for both users
        const usersSnapshot = await admin.firestore().collection("users")
            .where(admin.firestore.FieldPath.documentId(), "in", [user1Id, user2Id])
            .get();

        const usersMap = new Map();
        usersSnapshot.docs.forEach(doc => {
            usersMap.set(doc.id, doc.data());
        });

        const user1 = usersMap.get(user1Id);
        const user2 = usersMap.get(user2Id);

        if (!user1 || !user2) {
            console.error("One or both users not found");
            return { success: false, message: "Users not found" };
        }

        const messages = [];

        // Prepare message for User 1 (about User 2)
        if (user1.fcmToken) {
            messages.push({
                token: user1.fcmToken,
                notification: {
                    title: "配對成功！",
                    body: `你和 ${user2.name} 配對成功了！快來聊天吧！`,
                },
                data: {
                    type: "match",
                    chatRoomId: chatRoomId,
                    partnerId: user2Id,
                },
            });
        }

        // Prepare message for User 2 (about User 1)
        if (user2.fcmToken) {
            messages.push({
                token: user2.fcmToken,
                notification: {
                    title: "配對成功！",
                    body: `你和 ${user1.name} 配對成功了！快來聊天吧！`,
                },
                data: {
                    type: "match",
                    chatRoomId: chatRoomId,
                    partnerId: user1Id,
                },
            });
        }

        if (messages.length === 0) {
            return { success: true, message: "No tokens found to send notifications" };
        }

        // 3. Send messages
        // sendEach is available in newer firebase-admin, or sendAll.
        // Using sendEach (or sendMulticast if tokens are for same payload, but here payloads differ slightly due to names)

        const results = await Promise.all(messages.map(msg => admin.messaging().send(msg)));

        console.log(`Successfully sent match notifications to ${results.length} devices.`);

        return { success: true, count: results.length };

    } catch (error) {
        console.error("Error sending match notifications:", error);
        throw new functions.https.HttpsError(
            "internal",
            "Failed to send match notifications.",
            error
        );
    }
});
