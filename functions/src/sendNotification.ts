import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Initialize admin if not already initialized
if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Cloud Function for sending notifications to specific users
 * Callable by authenticated users.
 *
 * Usage:
 * call({
 *   targetUserIds: ["uid1", "uid2"],
 *   title: "Notification Title",
 *   body: "Notification Body",
 *   data: { key: "value" } // optional
 * })
 */
export const sendNotification = functions.https.onCall(async (data, context) => {
    // Verify that the request is made by an authenticated user
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "Only authenticated users can send notifications."
        );
    }

    const {
        title,
        body,
        data: customData,
        targetUserIds = [],
    } = data;

    // Validate required fields
    if (!title || !body) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Title and body are required."
        );
    }

    if (!targetUserIds || !Array.isArray(targetUserIds) || targetUserIds.length === 0) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "targetUserIds must be a non-empty array."
        );
    }

    try {
        // Fetch users to get tokens
        // Firestore 'in' query supports up to 10 values.
        // If targetUserIds > 10, we need to batch.
        // For matching, it's usually 1 or 2, so we can keep it simple or implement batching.
        // Implementing batching for robustness.

        const chunks = [];
        const chunkSize = 10;
        for (let i = 0; i < targetUserIds.length; i += chunkSize) {
            chunks.push(targetUserIds.slice(i, i + chunkSize));
        }

        let targetTokens: string[] = [];

        for (const chunk of chunks) {
            const usersSnapshot = await admin.firestore()
                .collection("users")
                .where(admin.firestore.FieldPath.documentId(), "in", chunk)
                .get();

            const chunkTokens = usersSnapshot.docs
                .map((doc) => doc.data().fcmToken)
                .filter((token) => token); // Remove null/undefined

            targetTokens = targetTokens.concat(chunkTokens);
        }

        if (targetTokens.length === 0) {
            console.log("No valid FCM tokens found for targets:", targetUserIds);
            return { success: false, message: "No tokens found" };
        }

        // Send multicast message
        const message = {
            notification: {
                title: title,
                body: body,
            },
            data: customData || {},
            tokens: targetTokens,
        };

        const response = await admin.messaging().sendEachForMulticast(message);

        console.log(`Successfully sent ${response.successCount} messages`);
        if (response.failureCount > 0) {
            console.log(`Failed to send ${response.failureCount} messages`);
            response.responses.forEach((resp, idx) => {
                if (!resp.success) {
                    console.error(`Error sending to token ${targetTokens[idx]}:`, resp.error);
                }
            });
        }

        // Log the notification (optional, but good for debugging)
        await admin.firestore().collection("notification_logs").add({
            title,
            body,
            targetUserIds,
            sentBy: context.auth.uid,
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
            successCount: response.successCount,
            failureCount: response.failureCount,
            type: "direct_notification"
        });

        return {
            success: true,
            successCount: response.successCount,
            failureCount: response.failureCount,
        };

    } catch (error) {
        console.error("Error sending notification:", error);
        throw new functions.https.HttpsError(
            "internal",
            "Failed to send notification.",
            error
        );
    }
});
