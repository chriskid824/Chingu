import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { getNotificationCopy, newMessageTest } from "./notification_content";

if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Sends a push notification to a specific user.
 *
 * Data payload:
 * - targetUserId: string (Required)
 * - notificationType: string (Required, e.g. 'new_message', 'match_success')
 * - params: Record<string, string> (Required for template replacement)
 * - data: Record<string, string> (Optional, for navigation/actions)
 */
export const sendNotification = functions.https.onCall(async (data, context) => {
    // 1. Verify Authentication
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "The function must be called while authenticated."
        );
    }

    const { targetUserId, notificationType, params, data: customData } = data;

    // 2. Validate Inputs
    if (!targetUserId || !notificationType) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "The function must be called with 'targetUserId' and 'notificationType'."
        );
    }

    try {
        // 3. Get Target User's FCM Token
        const userDoc = await admin.firestore().collection("users").doc(targetUserId).get();
        if (!userDoc.exists) {
             throw new functions.https.HttpsError(
                "not-found",
                `User ${targetUserId} not found.`
            );
        }

        const userData = userDoc.data();
        const fcmToken = userData?.fcmToken;

        if (!fcmToken) {
            console.log(`User ${targetUserId} has no FCM token. Skipping notification.`);
            return { success: false, reason: "no_token" };
        }

        // 4. Determine Notification Content (A/B Testing)
        let testId = "";
        if (notificationType === "new_message") {
            testId = newMessageTest.testId;
        }

        // Use 'control' variant by default for stability
        const content = getNotificationCopy(testId, "control", params || {});

        // Fallback if content is empty (e.g. unknown type)
        const title = content.title || "Notification";
        const body = content.body || "You have a new notification";

        // 5. Send Notification
        const message = {
            notification: {
                title: title,
                body: body,
            },
            data: {
                ...customData,
                click_action: "FLUTTER_NOTIFICATION_CLICK",
                type: notificationType,
            },
            token: fcmToken,
        };

        const response = await admin.messaging().send(message);
        console.log(`Successfully sent message to ${targetUserId}:`, response);

        return { success: true, messageId: response };

    } catch (error) {
        console.error("Error sending notification:", error);
        throw new functions.https.HttpsError(
            "internal",
            "Failed to send notification.",
            error
        );
    }
});
