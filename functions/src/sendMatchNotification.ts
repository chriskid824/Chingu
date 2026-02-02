import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { getNotificationCopy, matchSuccessTest } from "./notification_content";

if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Sends match notifications to both parties involved in a match.
 * Called when a double-like occurs.
 */
export const sendMatchNotification = functions.https.onCall(async (data, context) => {
    // 1. Authentication Check
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "The function must be called while authenticated."
        );
    }

    const { targetUserId } = data;
    const currentUserId = context.auth.uid;

    if (!targetUserId) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "The function must be called with one argument 'targetUserId'."
        );
    }

    try {
        // 2. Fetch Users
        const db = admin.firestore();
        const [currentUserDoc, targetUserDoc] = await Promise.all([
            db.collection("users").doc(currentUserId).get(),
            db.collection("users").doc(targetUserId).get()
        ]);

        if (!currentUserDoc.exists || !targetUserDoc.exists) {
            throw new functions.https.HttpsError(
                "not-found",
                "One or both users not found."
            );
        }

        const currentUserData = currentUserDoc.data();
        const targetUserData = targetUserDoc.data();

        // 3. Send Notifications
        const promises = [];

        // Notify Target User (User B) about Current User (User A)
        if (targetUserData?.fcmToken) {
             const copy = getNotificationCopy(
                matchSuccessTest.testId,
                'control', // Use control variant for now
                { userName: currentUserData?.name || 'Someone' }
            );

            const message = {
                notification: {
                    title: copy.title,
                    body: copy.body,
                },
                data: {
                    type: 'match_success',
                    partnerId: currentUserId,
                    click_action: 'FLUTTER_NOTIFICATION_CLICK'
                },
                token: targetUserData.fcmToken
            };

            promises.push(admin.messaging().send(message));
        }

        // Notify Current User (User A) about Target User (User B)
        if (currentUserData?.fcmToken) {
             const copy = getNotificationCopy(
                matchSuccessTest.testId,
                'control',
                { userName: targetUserData?.name || 'Someone' }
            );

            const message = {
                notification: {
                    title: copy.title,
                    body: copy.body,
                },
                data: {
                     type: 'match_success',
                     partnerId: targetUserId,
                     click_action: 'FLUTTER_NOTIFICATION_CLICK'
                },
                token: currentUserData.fcmToken
            };

            promises.push(admin.messaging().send(message));
        }

        if (promises.length > 0) {
            await Promise.all(promises);
            console.log(`Sent match notifications to ${promises.length} users.`);
        }

        return { success: true, sentCount: promises.length };

    } catch (error) {
        console.error("Error sending match notification:", error);
        throw new functions.https.HttpsError(
            "internal",
            "Failed to send match notifications.",
            error
        );
    }
});
