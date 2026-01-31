import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { getNotificationCopy, allNotificationTests } from "./notification_content";

if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Sends a push notification to a specific user.
 * Can be used for match success, new message, etc.
 * Supports A/B testing via notificationType.
 */
export const sendNotification = functions.https.onCall(async (data, context) => {
    // Verify authentication
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "Only authenticated users can send notifications."
        );
    }

    const {
        targetUserId,
        notificationType,
        params,
        title: customTitle,
        body: customBody,
        data: customData,
    } = data;

    if (!targetUserId) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "targetUserId is required."
        );
    }

    try {
        // 1. Get target user's FCM token
        const userDoc = await admin.firestore().collection("users").doc(targetUserId).get();
        if (!userDoc.exists) {
            console.log(`User ${targetUserId} not found`);
            return { success: false, error: "User not found" };
        }

        const userData = userDoc.data();
        const fcmToken = userData?.fcmToken;

        if (!fcmToken) {
            console.log(`User ${targetUserId} has no FCM token`);
            return { success: false, error: "User has no FCM token" };
        }

        // 2. Determine notification content
        let title = customTitle;
        let body = customBody;

        if (notificationType) {
            // Use A/B testing logic if notificationType is provided
            // We find the test configuration for this notification type
            const test = allNotificationTests.find((t) => t.notificationType === notificationType);

            if (test) {
                // Determine variant using DJB2 hash of userId + testId
                // This ensures consistency with the client-side assignment
                const djb2 = (str: string) => {
                    let hash = 5381;
                    for (let i = 0; i < str.length; i++) {
                        hash = ((hash << 5) + hash) + str.charCodeAt(i);
                    }
                    return hash >>> 0;
                };

                const hash = djb2(`${targetUserId}_${test.testId}`);
                const variantIndex = hash % test.variants.length;
                const variantId = test.variants[variantIndex].variantId;

                const copy = getNotificationCopy(test.testId, variantId, params || {});
                title = copy.title;
                body = copy.body;
            }
        }

        if (!title || !body) {
             if (!customTitle || !customBody) {
                 console.log("No title/body provided and failed to generate from type");
                 return { success: false, error: "Missing title/body" };
             }
        }

        // 3. Send notification
        const message = {
            notification: {
                title,
                body,
            },
            data: {
                ...customData,
                type: notificationType || "generic",
                click_action: "FLUTTER_NOTIFICATION_CLICK", // Standard for Flutter
            },
            token: fcmToken,
        };

        const response = await admin.messaging().send(message);
        console.log(`Successfully sent notification to ${targetUserId}:`, response);

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
