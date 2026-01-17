import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { getNotificationCopy, matchSuccessTest } from "./notification_content";

// Initialize admin if not already initialized
if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Cloud Function to send push notifications when a match occurs.
 * This is a Callable function called by the client (MatchingService).
 */
export const notifyMatch = functions.https.onCall(async (data, context) => {
    // Verify authentication
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
            "Missing user1Id, user2Id, or chatRoomId."
        );
    }

    try {
        // Fetch both users to get tokens and names
        const db = admin.firestore();
        const user1Doc = await db.collection("users").doc(user1Id).get();
        const user2Doc = await db.collection("users").doc(user2Id).get();

        if (!user1Doc.exists || !user2Doc.exists) {
            console.error("One or both users not found", user1Id, user2Id);
            return { success: false, error: "Users not found" };
        }

        const user1Data = user1Doc.data();
        const user2Data = user2Doc.data();

        const token1 = user1Data?.fcmToken;
        const token2 = user2Data?.fcmToken;
        const name1 = user1Data?.name || "Someone";
        const name2 = user2Data?.name || "Someone";

        // We use 'control' variant for now as we haven't implemented full A/B logic integration here
        const variant1 = 'control';
        const variant2 = 'control';

        const messages: admin.messaging.Message[] = [];

        // Prepare message for User 1 (about User 2)
        if (token1) {
            const content = getNotificationCopy(matchSuccessTest.testId, variant1, { userName: name2 });
            messages.push({
                token: token1,
                notification: {
                    title: content.title,
                    body: content.body,
                },
                data: {
                    actionType: "open_chat",
                    actionData: chatRoomId,
                    notificationId: `match_${chatRoomId}`,
                },
            });
        }

        // Prepare message for User 2 (about User 1)
        if (token2) {
            const content = getNotificationCopy(matchSuccessTest.testId, variant2, { userName: name1 });
            messages.push({
                token: token2,
                notification: {
                    title: content.title,
                    body: content.body,
                },
                data: {
                    actionType: "open_chat",
                    actionData: chatRoomId,
                    notificationId: `match_${chatRoomId}`,
                },
            });
        }

        if (messages.length > 0) {
             const response = await admin.messaging().sendEach(messages);
             console.log(`Sent match notifications. Success: ${response.successCount}, Failure: ${response.failureCount}`);
        }

        return { success: true };

    } catch (error) {
        console.error("Error sending match notifications:", error);
        throw new functions.https.HttpsError(
            "internal",
            "Failed to send notifications."
        );
    }
});
