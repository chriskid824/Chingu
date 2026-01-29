import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { getNotificationCopy } from "./notification_content";

if (admin.apps.length === 0) {
    admin.initializeApp();
}

export const sendNotification = functions.https.onCall(async (data, context) => {
    // 1. Auth check
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "User must be logged in.");
    }

    const { targetUserId, notificationType, params } = data;

    if (!targetUserId || !notificationType) {
        throw new functions.https.HttpsError("invalid-argument", "targetUserId and notificationType are required.");
    }

    try {
        // 2. Get target user's FCM token
        const userDoc = await admin.firestore().collection("users").doc(targetUserId).get();
        if (!userDoc.exists) {
            console.log(`User ${targetUserId} not found.`);
            return { success: false, error: "User not found" };
        }

        const userData = userDoc.data();
        const fcmToken = userData?.fcmToken;

        if (!fcmToken) {
            console.log(`User ${targetUserId} has no FCM token.`);
            return { success: false, error: "No FCM token" };
        }

        // 3. Generate content
        let testId = '';
        if (notificationType === 'match_success') {
            testId = 'match_success_copy_v1';
        } else if (notificationType === 'new_message') {
            testId = 'new_message_copy_v1';
        } else if (notificationType === 'event_reminder') {
            testId = 'event_reminder_copy_v1';
        }

        // Use 'control' variant by default
        const variantId = 'control';

        const content = getNotificationCopy(testId, variantId, params || {});

        // Fallback
        const title = content.title || "New Notification";
        const body = content.body || "You have a new notification.";

        // 4. Send
        const message = {
            notification: {
                title,
                body,
            },
            data: {
                type: notificationType,
                ...params // params values must be strings
            },
            token: fcmToken,
        };

        await admin.messaging().send(message);

        return { success: true };

    } catch (error) {
        console.error("Error sending notification:", error);
        throw new functions.https.HttpsError("internal", "Failed to send notification.");
    }
});
