import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { allNotificationTests, getNotificationCopy } from "./notification_content";

if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Cloud Function to send a push notification to a specific user.
 * Can handle raw title/body or A/B tested content based on notificationType.
 */
export const sendNotification = functions.https.onCall(async (data, context) => {
    // 1. Authentication Check
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "The function must be called while authenticated."
        );
    }

    const {
        targetUserId,
        title: rawTitle,
        body: rawBody,
        notificationType,
        params,
        data: customData,
        imageUrl
    } = data;

    if (!targetUserId) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "The function must be called with argument 'targetUserId'."
        );
    }

    try {
        // 2. Fetch Target User's FCM Token
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

        let title = rawTitle;
        let body = rawBody;

        // Security Check for 'match_success'
        if (notificationType === 'match_success' && context.auth.uid !== targetUserId) {
            const callerUid = context.auth.uid;
             // Check if caller liked target
            const callerLike = await admin.firestore().collection('swipes')
                .where('userId', '==', callerUid)
                .where('targetUserId', '==', targetUserId)
                .where('isLike', '==', true)
                .limit(1)
                .get();

            // Check if target liked caller
            const targetLike = await admin.firestore().collection('swipes')
                .where('userId', '==', targetUserId)
                .where('targetUserId', '==', callerUid)
                .where('isLike', '==', true)
                .limit(1)
                .get();

            if (callerLike.empty || targetLike.empty) {
                 throw new functions.https.HttpsError(
                        "permission-denied",
                        "No mutual match found."
                    );
            }
        }

        // 3. Resolve Content from A/B Test if notificationType provided
        if (notificationType) {
            const testConfig = allNotificationTests.find(t => t.notificationType === notificationType);
            if (testConfig) {
                // Fetch user's assigned variant
                const variantDoc = await admin.firestore()
                    .collection("users")
                    .doc(targetUserId)
                    .collection("ab_test_variants")
                    .doc(testConfig.testId)
                    .get();

                const variantId = variantDoc.exists ? variantDoc.data()?.variant : testConfig.defaultVariantId;

                const copy = getNotificationCopy(testConfig.testId, variantId || 'control', params || {});
                title = copy.title;
                body = copy.body;
            }
        }

        if (!title || !body) {
             // Fallback or error if no content could be generated and no raw content provided
             // But usually title/body are optional if notificationType is used.
             // If both are missing, we can't send.
             throw new functions.https.HttpsError(
                "invalid-argument",
                "Could not determine notification title and body."
            );
        }

        // 4. Send Notification
        const message: admin.messaging.Message = {
            token: fcmToken,
            notification: {
                title: title,
                body: body,
                ...(imageUrl && { imageUrl }),
            },
            data: customData || {},
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
