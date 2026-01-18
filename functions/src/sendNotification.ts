import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { getNotificationCopy } from "./notification_content";

// Ensure Firebase Admin is initialized
if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Cloud Function to send a targeted notification to a user.
 *
 * Data Params:
 * - targetUserId: string (Required)
 * - notificationType: string (Required) - e.g., 'match_success', 'new_message'
 * - params: object (Optional) - Dynamic parameters for the content (e.g., { userName: 'Alice' })
 */
export const sendNotification = functions.https.onCall(async (data, context) => {
    // 1. Authentication Check
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "User must be logged in to send notifications."
        );
    }

    const { targetUserId, notificationType, params } = data;

    // 2. Validation
    if (!targetUserId || !notificationType) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Missing targetUserId or notificationType."
        );
    }

    // Security Note:
    // Ideally, we should verify that context.auth.uid has permission to send this notification to targetUserId.
    // For 'match_success', we could verify a mutual match exists.
    // For 'new_message', we could verify a chat room exists.
    // Due to current scope, we are skipping deep verification but this is a potential open relay risk.

    try {
        // 3. Get User's FCM Token
        const userDoc = await admin.firestore().collection("users").doc(targetUserId).get();
        if (!userDoc.exists) {
            console.log(`User ${targetUserId} not found.`);
            return { success: false, reason: "user_not_found" };
        }

        const userData = userDoc.data();
        const fcmToken = userData?.fcmToken;

        if (!fcmToken) {
            console.log(`User ${targetUserId} has no FCM token.`);
            return { success: false, reason: "no_token" };
        }

        // 4. Determine A/B Test Variant
        const hash = simpleHash(targetUserId);

        const isControl = (hash % 2 === 0);
        let variantId = 'control';

        if (!isControl) {
            if (notificationType === 'match_success') {
                variantId = (hash % 4 === 1) ? 'friendly' : 'urgent';
            } else {
                 if (notificationType === 'new_message') variantId = (hash % 4 === 1) ? 'casual' : 'engaging';
                 if (notificationType === 'event_reminder') variantId = (hash % 4 === 1) ? 'countdown' : 'motivating';
            }
        }

        // 5. Generate Content
        let testId = '';
        if (notificationType === 'match_success') testId = 'match_success_copy_v1';
        else if (notificationType === 'new_message') testId = 'new_message_copy_v1';
        else if (notificationType === 'event_reminder') testId = 'event_reminder_copy_v1';
        else if (notificationType === 'inactivity_reminder') testId = 'inactivity_copy_v1';

        const content = getNotificationCopy(testId, variantId, params || {});

        // Fallback content
        const title = content.title || "New Notification";
        const body = content.body || "You have a new update.";

        // 6. Send FCM Message
        const message = {
            notification: {
                title: title,
                body: body,
            },
            data: {
                type: notificationType,
                ...params // Include params in data payload for client handling
            },
            token: fcmToken,
        };

        await admin.messaging().send(message);

        // 7. Log / Track
        await admin.firestore().collection("notification_events").add({
            userId: targetUserId,
            type: notificationType,
            testId: testId,
            variantId: variantId,
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
            status: 'sent',
            senderId: context.auth.uid // Track who sent it
        });

        return { success: true };

    } catch (error) {
        console.error("Error sending notification:", error);
        throw new functions.https.HttpsError(
            "internal",
            "Failed to send notification."
        );
    }
});

function simpleHash(str: string): number {
    let hash = 0;
    for (let i = 0; i < str.length; i++) {
        const char = str.charCodeAt(i);
        hash = ((hash << 5) - hash) + char;
        hash = hash & hash; // Convert to 32bit integer
    }
    return Math.abs(hash);
}
