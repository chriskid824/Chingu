import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { allNotificationTests, getNotificationCopy, NotificationCopyVariant } from "./notification_content";

// Ensure Firebase Admin is initialized
if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Assigns a variant to a user for a given test.
 * This is a simple random assignment.
 */
function assignVariant(variants: NotificationCopyVariant[]): string {
    if (variants.length === 0) return "control";
    const randomIndex = Math.floor(Math.random() * variants.length);
    return variants[randomIndex].variantId;
}

/**
 * Cloud Function to send a notification with A/B testing support.
 *
 * Usage:
 * call sendNotification({
 *   userId: "target_user_uid",
 *   notificationType: "click_optimization", // matches notificationType in notification_content.ts
 *   params: { "key": "value" } // optional params for copy replacement
 * })
 */
export const sendNotification = functions.https.onCall(async (data, context) => {
    // 1. Authentication Check
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "The function must be called while authenticated."
        );
    }

    const db = admin.firestore();

    // 2. Authorization Check (Admin Only)
    // Check if user is in an 'admins' collection
    const adminDoc = await db.collection("admins").doc(context.auth.uid).get();
    if (!adminDoc.exists) {
        throw new functions.https.HttpsError(
            "permission-denied",
            "Only admins can send notifications."
        );
    }

    const { userId, notificationType, params = {} } = data;

    if (!userId || !notificationType) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "The function must be called with argument 'userId' and 'notificationType'."
        );
    }

    try {
        // 3. Find Test Configuration
        const testConfig = allNotificationTests.find(t => t.notificationType === notificationType);

        if (!testConfig) {
             throw new functions.https.HttpsError(
                "not-found",
                `Notification type '${notificationType}' not found.`
            );
        }

        const testId = testConfig.testId;
        const variantRef = db.collection("users").doc(userId).collection("ab_test_variants").doc(testId);

        // 4. Get or Assign Variant (Transactional)
        const variantId = await db.runTransaction(async (transaction) => {
            const doc = await transaction.get(variantRef);
            if (doc.exists) {
                return doc.data()?.variant as string;
            } else {
                const newVariantId = assignVariant(testConfig.variants);
                transaction.set(variantRef, {
                    testId: testId,
                    variant: newVariantId,
                    assignedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
                return newVariantId;
            }
        });

        // 5. Get Copy
        const { title, body } = getNotificationCopy(testId, variantId, params);

        // 6. Get User's FCM Token
        const userDoc = await db.collection("users").doc(userId).get();
        if (!userDoc.exists) {
            throw new functions.https.HttpsError("not-found", "User not found");
        }

        const fcmToken = userDoc.data()?.fcmToken;
        if (!fcmToken) {
             return { success: false, error: "User has no FCM token" };
        }

        // 7. Send Notification
        const message = {
            notification: {
                title,
                body,
            },
            data: {
                notificationType,
                testId,
                variantId,
                ...params // Include params in data payload for client handling
            },
            token: fcmToken,
        };

        const response = await admin.messaging().send(message);

        // 8. Log the send event for analysis
        await db.collection("ab_test_events").add({
            testId,
            userId,
            variant: variantId,
            eventName: "notification_sent",
            notificationType,
            messageId: response,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });

        return { success: true, messageId: response, variantId };

    } catch (error) {
        console.error("Error sending notification:", error);
        throw new functions.https.HttpsError(
            "internal",
            "Failed to send notification",
            error
        );
    }
});
