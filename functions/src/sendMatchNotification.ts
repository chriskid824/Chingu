import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { getNotificationCopy, matchSuccessTest } from "./notification_content";

// Ensure app is initialized
if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Cloud Function to send notifications when a match occurs.
 * Takes user1Id and user2Id, fetches their profiles to get names and FCM tokens,
 * and sends a personalized notification to each user.
 */
export const sendMatchNotification = functions.https.onCall(async (data, context) => {
    // 1. Verify Authentication
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "The function must be called while authenticated."
        );
    }

    const { user1Id, user2Id } = data;

    if (!user1Id || !user2Id) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "The function must be called with two user IDs: user1Id and user2Id."
        );
    }

    try {
        const db = admin.firestore();

        // 2. Fetch User Data
        const [user1Doc, user2Doc] = await Promise.all([
            db.collection("users").doc(user1Id).get(),
            db.collection("users").doc(user2Id).get()
        ]);

        if (!user1Doc.exists || !user2Doc.exists) {
             throw new functions.https.HttpsError(
                "not-found",
                "One or both users not found."
            );
        }

        const user1Data = user1Doc.data();
        const user2Data = user2Doc.data();

        if (!user1Data || !user2Data) {
             throw new functions.https.HttpsError(
                "data-loss",
                "User data is missing."
            );
        }

        const user1Token = user1Data.fcmToken;
        const user2Token = user2Data.fcmToken;
        const user1Name = user1Data.name || "Someone";
        const user2Name = user2Data.name || "Someone";

        const messages: admin.messaging.Message[] = [];

        // 3. Prepare Notification for User 1 (about User 2)
        if (user1Token) {
            const copy = getNotificationCopy(
                matchSuccessTest.testId,
                matchSuccessTest.defaultVariantId, // Using default variant for now
                { userName: user2Name }
            );

            messages.push({
                token: user1Token,
                notification: {
                    title: copy.title,
                    body: copy.body,
                },
                data: {
                    type: "match_success",
                    partnerId: user2Id,
                    click_action: "FLUTTER_NOTIFICATION_CLICK"
                }
            });
        }

        // 4. Prepare Notification for User 2 (about User 1)
        if (user2Token) {
             const copy = getNotificationCopy(
                matchSuccessTest.testId,
                matchSuccessTest.defaultVariantId,
                { userName: user1Name }
            );

            messages.push({
                token: user2Token,
                notification: {
                    title: copy.title,
                    body: copy.body,
                },
                 data: {
                    type: "match_success",
                    partnerId: user1Id,
                    click_action: "FLUTTER_NOTIFICATION_CLICK"
                }
            });
        }

        // 5. Send Notifications
        if (messages.length > 0) {
             const response = await admin.messaging().sendEach(messages);
             console.log(`Match notifications sent. Success: ${response.successCount}, Failure: ${response.failureCount}`);

             if (response.failureCount > 0) {
                 response.responses.forEach((resp, idx) => {
                     if (!resp.success) {
                         console.error(`Error sending to token ${messages[idx].token}:`, resp.error);
                     }
                 });
             }

             return {
                 success: true,
                 successCount: response.successCount,
                 failureCount: response.failureCount
             };
        }

        return { success: true, message: "No valid tokens found to send notifications." };

    } catch (error) {
        console.error("Error sending match notification:", error);
        throw new functions.https.HttpsError(
            "internal",
            "Failed to send match notification",
            error
        );
    }
});
