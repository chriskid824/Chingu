import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { matchSuccessTest, getNotificationCopy } from "./notification_content";

/**
 * Cloud Function to send match notifications to both users
 *
 * Logic:
 * 1. Takes userId (initiator), targetUserId (target), and chatRoomId.
 * 2. Fetches user details to get names and FCM tokens.
 * 3. Sends notification to both users.
 */
export const sendMatchNotification = functions.https.onCall(async (data, context) => {
    // Verify authentication
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "The function must be called while authenticated."
        );
    }

    const { userId, targetUserId, chatRoomId } = data;

    if (!userId || !targetUserId || !chatRoomId) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Missing required arguments: userId, targetUserId, chatRoomId."
        );
    }

    try {
        // Fetch users in parallel
        const [user1Doc, user2Doc] = await Promise.all([
            admin.firestore().collection("users").doc(userId).get(),
            admin.firestore().collection("users").doc(targetUserId).get(),
        ]);

        if (!user1Doc.exists || !user2Doc.exists) {
            console.error(`One or both users not found: ${userId}, ${targetUserId}`);
            // Don't throw to client, just log and return
            return { success: false, error: "Users not found" };
        }

        const user1Data = user1Doc.data();
        const user2Data = user2Doc.data();

        if (!user1Data || !user2Data) {
            return { success: false, error: "User data is empty" };
        }

        const notifications = [];

        // Notify User 1 (Initiator) about User 2 (Target)
        if (user1Data.fcmToken) {
            const content = getNotificationCopy(matchSuccessTest.testId, 'control', {
                userName: user2Data.name || 'Someone',
            });

            const message = {
                notification: {
                    title: content.title,
                    body: content.body,
                },
                data: {
                    actionType: 'open_chat',
                    actionData: chatRoomId,
                    click_action: 'FLUTTER_NOTIFICATION_CLICK',
                    type: 'match_success',
                    targetUserId: targetUserId,
                    chatRoomId: chatRoomId,
                },
                token: user1Data.fcmToken,
            };
            notifications.push(admin.messaging().send(message));
        }

        // Notify User 2 (Target) about User 1 (Initiator)
        if (user2Data.fcmToken) {
            const content = getNotificationCopy(matchSuccessTest.testId, 'control', {
                userName: user1Data.name || 'Someone',
            });

            const message = {
                notification: {
                    title: content.title,
                    body: content.body,
                },
                data: {
                    actionType: 'open_chat',
                    actionData: chatRoomId,
                    click_action: 'FLUTTER_NOTIFICATION_CLICK',
                    type: 'match_success',
                    targetUserId: userId,
                    chatRoomId: chatRoomId,
                },
                token: user2Data.fcmToken,
            };
            notifications.push(admin.messaging().send(message));
        }

        await Promise.allSettled(notifications);

        return { success: true, count: notifications.length };
    } catch (error) {
        console.error("Error sending match notifications:", error);
        throw new functions.https.HttpsError(
            "internal",
            "Failed to send notifications",
            error
        );
    }
});
