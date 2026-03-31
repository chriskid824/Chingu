import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { getNotificationCopy, getVariantForUser, allNotificationTests } from "./notification_content";

// Conditionally initialize Firebase Admin
if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Send a notification to a user with A/B tested copy.
 *
 * This function handles:
 * 1. Fetching the target user's FCM token.
 * 2. Determining the A/B test variant for the user.
 * 3. Generating the appropriate notification content.
 * 4. Sending the notification via FCM.
 * 5. Logging the notification send event for analysis.
 */
export const sendNotification = functions.https.onCall(async (data, context) => {
    // 1. Authentication Check
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "The function must be called while authenticated."
        );
    }

    const { targetUserId, notificationType, params = {} } = data;

    // 2. Validation
    if (!targetUserId || !notificationType) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "targetUserId and notificationType are required."
        );
    }

    try {
        // 3. Get User's FCM Token
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
            // It's possible the user has no token (not logged in on mobile, or disabled notifications)
            console.log(`User ${targetUserId} has no FCM token. Skipping notification.`);
            return { success: false, reason: "no_fcm_token" };
        }

        // Resolve testId from notificationType if possible
        const testConfig = allNotificationTests.find(t => t.notificationType === notificationType);
        const testId = testConfig ? testConfig.testId : notificationType;

        // 4. Determine A/B Variant
        const variantId = getVariantForUser(targetUserId, testId);

        // 5. Get Copy
        const { title, body } = getNotificationCopy(testId, variantId, params);

        if (!title && !body) {
             // If no copy is found, we might want to fallback or throw.
             // getNotificationCopy returns empty strings if not found.
             console.warn(`No copy found for testId: ${testId}, variant: ${variantId}`);
             // Proceeding might send an empty notification which is bad.
             throw new functions.https.HttpsError(
                "internal",
                "Failed to generate notification content."
            );
        }

        // 6. Send Notification
        const message = {
            notification: {
                title,
                body,
            },
            data: {
                ...params,
                notificationType,
                testId,
                variantId, // Send variantId to client for tracking clicks/conversions
                click_action: "FLUTTER_NOTIFICATION_CLICK", // Standard for Flutter
            },
            token: fcmToken,
        };

        const response = await admin.messaging().send(message);

        // 7. Log Event
        await admin.firestore().collection("notification_logs").add({
            targetUserId,
            notificationType,
            testId,
            variantId,
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
            messageId: response,
            success: true,
            senderId: context.auth.uid
        });

        return { success: true, messageId: response, variantId };

    } catch (error) {
        console.error("Error sending notification:", error);

        // Log failure
        try {
             await admin.firestore().collection("notification_logs").add({
                targetUserId,
                notificationType,
                sentAt: admin.firestore.FieldValue.serverTimestamp(),
                success: false,
                error: error instanceof Error ? error.message : String(error),
                senderId: context.auth.uid
            });
        } catch (logError) {
            console.error("Failed to log notification error:", logError);
        }

        // Re-throw appropriate error
        if (error instanceof functions.https.HttpsError) {
            throw error;
        }

        throw new functions.https.HttpsError(
            "internal",
            "Failed to send notification.",
            error
        );
    }
});
