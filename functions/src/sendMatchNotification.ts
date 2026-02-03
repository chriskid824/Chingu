import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { getNotificationCopy, matchSuccessTest } from "./notification_content";

// Ensure app is initialized
if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Cloud Function to send match notifications to both users
 * Called when a match is successfully created on the client side.
 *
 * Args:
 * - targetUserId: The ID of the user who was matched (swiped right on).
 * - chatRoomId: The ID of the created chat room.
 */
export const sendMatchNotification = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "The function must be called while authenticated."
        );
    }

    const currentUserId = context.auth.uid;
    const { targetUserId, chatRoomId } = data;

    if (!targetUserId || !chatRoomId) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "The function must be called with targetUserId and chatRoomId."
        );
    }

    try {
        // Fetch both users to get names and tokens
        const userRefs = [
            admin.firestore().collection("users").doc(currentUserId),
            admin.firestore().collection("users").doc(targetUserId)
        ];

        const [currentUserSnap, targetUserSnap] = await Promise.all(userRefs.map(ref => ref.get()));

        if (!currentUserSnap.exists || !targetUserSnap.exists) {
             throw new functions.https.HttpsError(
                "not-found",
                "One or both users not found."
            );
        }

        const currentUserData = currentUserSnap.data()!;
        const targetUserData = targetUserSnap.data()!;

        // Send to Target User (notifying them about Current User)
        const targetNotification = getNotificationCopy(
            matchSuccessTest.testId,
            matchSuccessTest.defaultVariantId,
            { userName: currentUserData.name }
        );

        const targetToken = targetUserData.fcmToken;

        // Send to Current User (notifying them about Target User)
        const currentNotification = getNotificationCopy(
            matchSuccessTest.testId,
            matchSuccessTest.defaultVariantId,
            { userName: targetUserData.name }
        );

        const currentToken = currentUserData.fcmToken;

        const messages = [];

        if (targetToken) {
            messages.push({
                notification: {
                    title: targetNotification.title,
                    body: targetNotification.body,
                },
                data: {
                    actionType: "open_chat",
                    actionData: chatRoomId,
                    chatRoomId: chatRoomId,
                    click_action: "FLUTTER_NOTIFICATION_CLICK"
                },
                token: targetToken
            });
        }

        if (currentToken) {
            messages.push({
                notification: {
                    title: currentNotification.title,
                    body: currentNotification.body,
                },
                data: {
                    actionType: "open_chat",
                    actionData: chatRoomId,
                    chatRoomId: chatRoomId,
                    click_action: "FLUTTER_NOTIFICATION_CLICK"
                },
                token: currentToken
            });
        }

        if (messages.length > 0) {
            const responses = await Promise.all(messages.map(msg => admin.messaging().send(msg)));
            console.log(`Sent ${responses.length} match notifications.`);
        }

        return { success: true };

    } catch (error) {
        console.error("Error sending match notification:", error);
        throw new functions.https.HttpsError(
            "internal",
            "Unable to send match notification",
            error
        );
    }
});
