import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

/**
 * Cloud Function for sending targeted notifications to a specific user
 *
 * Usage:
 * - targetUserId: string (Required)
 * - title: string (Required)
 * - body: string (Required)
 * - imageUrl: string (Optional)
 * - type: string (Optional, default 'system')
 * - data: object (Optional custom data)
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
        targetUserId,
        title,
        body,
        imageUrl,
        type = "system",
        data: customData = {},
    } = data;

    // Validate required fields
    if (!targetUserId || !title || !body) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "targetUserId, title, and body are required."
        );
    }

    try {
        // Get target user's FCM token
        const userDoc = await admin.firestore()
            .collection("users")
            .doc(targetUserId)
            .get();

        if (!userDoc.exists) {
            throw new functions.https.HttpsError(
                "not-found",
                "Target user not found."
            );
        }

        const userData = userDoc.data();
        const fcmToken = userData?.fcmToken;

        if (!fcmToken) {
            console.log(`User ${targetUserId} has no FCM token.`);
            return {
                success: false,
                message: "User has no FCM token",
                recipientId: targetUserId,
            };
        }

        // Ensure all custom data values are strings
        const safeCustomData: Record<string, string> = {};
        if (customData && typeof customData === "object") {
            for (const [key, value] of Object.entries(customData)) {
                safeCustomData[key] = String(value);
            }
        }

        // Construct message
        const message = {
            notification: {
                title: title,
                body: body,
                ...(imageUrl && { imageUrl }),
            },
            data: {
                ...safeCustomData,
                type,
                click_action: "FLUTTER_NOTIFICATION_CLICK",
                timestamp: Date.now().toString(),
            },
            token: fcmToken,
        };

        // Send message
        const response = await admin.messaging().send(message);
        console.log(`Successfully sent notification to ${targetUserId}:`, response);

        return {
            success: true,
            messageId: response,
            recipientId: targetUserId,
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
