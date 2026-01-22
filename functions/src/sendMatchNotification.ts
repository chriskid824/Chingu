import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { getNotificationCopy, matchSuccessTest } from "./notification_content";

if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Cloud Function to send notifications when a match occurs.
 * Should be called when a mutual like is confirmed.
 */
export const sendMatchNotification = functions.https.onCall(async (data, context) => {
    // 1. Authentication check
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "The function must be called while authenticated."
        );
    }

    const { user1Id, user2Id, chatRoomId } = data;

    if (!user1Id || !user2Id) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "user1Id and user2Id are required."
        );
    }

    try {
        // 2. Fetch user data
        const [user1Doc, user2Doc] = await Promise.all([
            admin.firestore().collection("users").doc(user1Id).get(),
            admin.firestore().collection("users").doc(user2Id).get()
        ]);

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

        const notifications = [];

        // 3. Prepare notification for User 1 (You matched with User 2)
        if (user1Token) {
            const { title, body } = getNotificationCopy(
                matchSuccessTest.testId,
                matchSuccessTest.defaultVariantId, // Or implement A/B test assignment logic
                { userName: user2Data?.name || "Someone" }
            );

            const message = {
                notification: {
                    title: title,
                    body: body,
                },
                data: {
                    type: "match", // Legacy
                    notificationType: "match",
                    actionType: "open_chat",
                    actionData: chatRoomId || user2Id, // Navigate to chat
                    otherUserId: user2Id,
                    click_action: "FLUTTER_NOTIFICATION_CLICK"
                },
                token: user1Token
            };
            notifications.push(admin.messaging().send(message));
        }

        // 4. Prepare notification for User 2 (You matched with User 1)
        if (user2Token) {
            const { title, body } = getNotificationCopy(
                matchSuccessTest.testId,
                matchSuccessTest.defaultVariantId,
                { userName: user1Data?.name || "Someone" }
            );

            const message = {
                notification: {
                    title: title,
                    body: body,
                },
                data: {
                    type: "match",
                    notificationType: "match",
                    actionType: "open_chat",
                    actionData: chatRoomId || user1Id,
                    otherUserId: user1Id,
                    click_action: "FLUTTER_NOTIFICATION_CLICK"
                },
                token: user2Token
            };
            notifications.push(admin.messaging().send(message));
        }

        // 5. Send notifications
        if (notifications.length > 0) {
            await Promise.all(notifications);
        }

        return { success: true, sentCount: notifications.length };

    } catch (error) {
        console.error("Error sending match notification:", error);
        throw new functions.https.HttpsError(
            "internal",
            "Failed to send match notification."
        );
    }
});
