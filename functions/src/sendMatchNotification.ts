import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { getNotificationCopy, matchSuccessTest } from "./notification_content";

// Ensure Firebase Admin is initialized
if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Sends a notification to both users when a match is successful.
 * Callable function.
 */
export const sendMatchNotification = functions.https.onCall(async (data, context) => {
    // 1. Auth check
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
            "user1Id and user2Id are required."
        );
    }

    try {
        // 2. Fetch users
        const [user1Doc, user2Doc] = await Promise.all([
            admin.firestore().collection("users").doc(user1Id).get(),
            admin.firestore().collection("users").doc(user2Id).get()
        ]);

        if (!user1Doc.exists || !user2Doc.exists) {
            console.error(`User(s) not found: ${user1Id}, ${user2Id}`);
            throw new functions.https.HttpsError("not-found", "One or both users not found");
        }

        const user1 = user1Doc.data();
        const user2 = user2Doc.data();

        // 3. Prepare notifications
        const messages: admin.messaging.Message[] = [];

        // Helper to prepare message for a user
        const prepareMessage = (targetUser: any, partner: any, partnerId: string) => {
            if (!targetUser?.fcmToken) return null;

            // Determine variant
            // Check if user has abTestAssignments
            const assignments = targetUser.abTestAssignments || {};
            const variantId = assignments[matchSuccessTest.testId] || matchSuccessTest.defaultVariantId;

            // Generate content
            const { title, body } = getNotificationCopy(
                matchSuccessTest.testId,
                variantId,
                { userName: partner?.name || 'Someone' }
            );

            return {
                token: targetUser.fcmToken,
                notification: {
                    title,
                    body,
                },
                data: {
                    type: "match_success",
                    partnerId: partnerId,
                    click_action: "FLUTTER_NOTIFICATION_CLICK"
                }
            } as admin.messaging.Message;
        };

        const msg1 = prepareMessage(user1, user2, user2Id);
        if (msg1) messages.push(msg1);

        const msg2 = prepareMessage(user2, user1, user1Id);
        if (msg2) messages.push(msg2);

        // 4. Send notifications
        let successCount = 0;
        let failureCount = 0;

        if (messages.length > 0) {
            const response = await admin.messaging().sendEach(messages);
            successCount = response.successCount;
            failureCount = response.failureCount;

            if (response.failureCount > 0) {
                console.warn(`Failed to send ${response.failureCount} match notifications.`);
                response.responses.forEach((resp, idx) => {
                    if (!resp.success) {
                         console.error(`Error sending to token ${idx}:`, resp.error);
                    }
                });
            }
        }

        // 5. Log stats
        await admin.firestore().collection("notification_stats").add({
            type: "match_success",
            user1Id,
            user2Id,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            successCount,
            failureCount
        });

        return { success: true, sentCount: successCount };

    } catch (error) {
        console.error("Error sending match notification:", error);
        throw new functions.https.HttpsError("internal", "Failed to send notification");
    }
});
