import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { assignVariant, getNotificationCopy, matchSuccessTest } from "./notification_content";

if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Sends match success notifications to both users.
 * This should be called when a match is confirmed.
 */
export const sendMatchNotification = functions.https.onCall(async (data, context) => {
    // 1. Authentication check
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "The function must be called while authenticated."
        );
    }

    const currentUserId = context.auth.uid;
    const { matchedUserId } = data;

    if (!matchedUserId) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "The function must be called with a matchedUserId."
        );
    }

    try {
        // 2. Fetch both users
        const db = admin.firestore();
        const [currentUserDoc, matchedUserDoc] = await Promise.all([
            db.collection("users").doc(currentUserId).get(),
            db.collection("users").doc(matchedUserId).get()
        ]);

        if (!currentUserDoc.exists || !matchedUserDoc.exists) {
             throw new functions.https.HttpsError(
                "not-found",
                "One or both users not found."
            );
        }

        const currentUser = currentUserDoc.data()!;
        const matchedUser = matchedUserDoc.data()!;

        // 3. Prepare notifications
        const messages: admin.messaging.Message[] = [];
        const testId = matchSuccessTest.testId;

        // Message to Current User (You matched with MatchedUser)
        if (currentUser.fcmToken) {
            const variantId = assignVariant(testId, currentUserId);
            const content = getNotificationCopy(testId, variantId, {
                userName: matchedUser.name || "Someone"
            });

            messages.push({
                token: currentUser.fcmToken,
                notification: {
                    title: content.title,
                    body: content.body,
                },
                data: {
                    type: "match",
                    matchUserId: matchedUserId,
                    click_action: "FLUTTER_NOTIFICATION_CLICK",
                }
            });
        }

        // Message to Matched User (You matched with CurrentUser)
        if (matchedUser.fcmToken) {
            const variantId = assignVariant(testId, matchedUserId);
            const content = getNotificationCopy(testId, variantId, {
                userName: currentUser.name || "Someone"
            });

            messages.push({
                token: matchedUser.fcmToken,
                notification: {
                    title: content.title,
                    body: content.body,
                },
                data: {
                    type: "match",
                    matchUserId: currentUserId,
                    click_action: "FLUTTER_NOTIFICATION_CLICK",
                }
            });
        }

        // 4. Send messages
        if (messages.length > 0) {
             const responses = await Promise.all(messages.map(msg => admin.messaging().send(msg)));

             // Log the notification
             await db.collection("notification_logs").add({
                 type: "match_success",
                 senderId: currentUserId,
                 receiverIds: [currentUserId, matchedUserId],
                 sentAt: admin.firestore.FieldValue.serverTimestamp(),
                 successCount: responses.length,
             });

             return { success: true, sentCount: responses.length };
        }

        return { success: true, sentCount: 0 };

    } catch (error) {
        console.error("Error sending match notifications:", error);
        throw new functions.https.HttpsError(
            "internal",
            "Failed to send match notifications.",
            error
        );
    }
});
