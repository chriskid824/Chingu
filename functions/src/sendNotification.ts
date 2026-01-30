import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (!admin.apps.length) {
    admin.initializeApp();
}

/**
 * Sends a push notification to a specific user.
 * Can be called by authenticated users to notify others (e.g., chat messages).
 *
 * data: {
 *   recipientId: string,
 *   title: string,
 *   body: string,
 *   data?: Record<string, string>,
 *   imageUrl?: string
 * }
 */
export const sendNotification = functions.https.onCall(async (data, context) => {
    // 1. Verify authentication
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "The function must be called while authenticated."
        );
    }

    const { recipientId, title, body, data: customData, imageUrl } = data;

    // 2. Validate input
    if (!recipientId || !title || !body) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "recipientId, title, and body are required."
        );
    }

    try {
        // 3. Get recipient's FCM token
        const userDoc = await admin.firestore().collection("users").doc(recipientId).get();

        if (!userDoc.exists) {
            console.log(`User ${recipientId} not found, skipping notification.`);
            return { success: false, error: "User not found" };
        }

        const userData = userDoc.data();
        const fcmToken = userData?.fcmToken;

        if (!fcmToken) {
            console.log(`User ${recipientId} has no FCM token, skipping.`);
            return { success: false, error: "No FCM token" };
        }

        // 4. Send notification
        // fcmToken can be string or string[]
        const tokens = Array.isArray(fcmToken) ? fcmToken : [fcmToken];

        if (tokens.length === 0) {
            return { success: false, error: "Empty FCM token list" };
        }

        const message: admin.messaging.MulticastMessage = {
            notification: {
                title: title,
                body: body,
                ...(imageUrl && { imageUrl }),
            },
            data: customData || {},
            tokens: tokens,
        };

        // Use sendEachForMulticast to handle multiple tokens (e.g. multiple devices)
        const response = await admin.messaging().sendEachForMulticast(message);

        // Optional: Remove invalid tokens
        if (response.failureCount > 0) {
            const failedTokens: string[] = [];
            response.responses.forEach((resp, idx) => {
                if (!resp.success) {
                    failedTokens.push(tokens[idx]);
                    console.error(`Failed to send to token: ${tokens[idx]}`, resp.error);
                }
            });
            // Here we could implement token cleanup logic if needed
        }

        return {
            success: true,
            successCount: response.successCount,
            failureCount: response.failureCount
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
