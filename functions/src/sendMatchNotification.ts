import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { getNotificationCopy, matchSuccessTest } from "./notification_content";

/**
 * Sends push notifications to both users when a match occurs.
 * This function should be called after a successful match is detected on the client.
 * It verifies the match exists in Firestore before sending notifications.
 */
export const sendMatchNotification = functions.https.onCall(async (data, context) => {
    // 1. Verify Authentication
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "The function must be called while authenticated."
        );
    }

    const currentUserId = context.auth.uid;
    const { matchedUserId } = data;

    if (!matchedUserId || typeof matchedUserId !== "string") {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "The function must be called with a valid matchedUserId."
        );
    }

    const firestore = admin.firestore();

    try {
        // 2. Verify Mutual Match (Security Check)
        // Check if current user liked matched user
        const currentUserSwipe = await firestore.collection("swipes")
            .where("userId", "==", currentUserId)
            .where("targetUserId", "==", matchedUserId)
            .where("isLike", "==", true)
            .limit(1)
            .get();

        if (currentUserSwipe.empty) {
            throw new functions.https.HttpsError(
                "permission-denied",
                "No like record found from current user."
            );
        }

        // Check if matched user liked current user
        const matchedUserSwipe = await firestore.collection("swipes")
            .where("userId", "==", matchedUserId)
            .where("targetUserId", "==", currentUserId)
            .where("isLike", "==", true)
            .limit(1)
            .get();

        if (matchedUserSwipe.empty) {
            throw new functions.https.HttpsError(
                "failed-precondition",
                "No mutual match found. The other user has not liked you back."
            );
        }

        // 3. Fetch User Details (for names and tokens)
        const currentUserDoc = await firestore.collection("users").doc(currentUserId).get();
        const matchedUserDoc = await firestore.collection("users").doc(matchedUserId).get();

        if (!currentUserDoc.exists || !matchedUserDoc.exists) {
            throw new functions.https.HttpsError(
                "not-found",
                "One or both user profiles not found."
            );
        }

        const currentUserData = currentUserDoc.data()!;
        const matchedUserData = matchedUserDoc.data()!;

        const currentUserToken = currentUserData.fcmToken;
        const matchedUserToken = matchedUserData.fcmToken;

        // 4. Prepare Notifications
        const messages: admin.messaging.Message[] = [];

        // Notification for Current User
        if (currentUserToken) {
            // Use A/B test copy - simple hash for variant assignment
            // (Using last char of uid to pick a variant deterministically if we wanted,
            // but here we just use default 'control' for simplicity as we don't have the AB service logic ported)
            // Or we can just pass 'control' which is the default.

            const copy = getNotificationCopy(
                matchSuccessTest.testId,
                matchSuccessTest.defaultVariantId,
                { userName: matchedUserData.name }
            );

            messages.push({
                notification: {
                    title: copy.title,
                    body: copy.body,
                },
                data: {
                    type: "match_success",
                    matchedUserId: matchedUserId,
                    click_action: "FLUTTER_NOTIFICATION_CLICK",
                    actionType: "open_chat",
                    actionData: matchedUserId,
                },
                token: currentUserToken,
            });
        }

        // Notification for Matched User
        if (matchedUserToken) {
             const copy = getNotificationCopy(
                matchSuccessTest.testId,
                matchSuccessTest.defaultVariantId,
                { userName: currentUserData.name }
            );

            messages.push({
                notification: {
                    title: copy.title,
                    body: copy.body,
                },
                data: {
                    type: "match_success",
                    matchedUserId: currentUserId,
                    click_action: "FLUTTER_NOTIFICATION_CLICK",
                    actionType: "open_chat",
                    actionData: currentUserId,
                },
                token: matchedUserToken,
            });
        }

        // 5. Send Notifications
        if (messages.length > 0) {
            const batchResponse = await admin.messaging().sendEach(messages);
            console.log("Match notifications sent:", batchResponse);

            return {
                success: true,
                sentCount: batchResponse.successCount,
                failureCount: batchResponse.failureCount
            };
        } else {
            console.log("No FCM tokens found for either user.");
            return { success: true, message: "No tokens found" };
        }

    } catch (error) {
        console.error("Error sending match notification:", error);
        // Re-throw if it's already an HttpsError, otherwise wrap it
        if (error instanceof functions.https.HttpsError) {
            throw error;
        }
        throw new functions.https.HttpsError(
            "internal",
            "Failed to send match notifications.",
            error
        );
    }
});
