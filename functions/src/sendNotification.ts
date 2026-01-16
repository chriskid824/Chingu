import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { getNotificationCopy, newMessageTest } from "./notification_content";
import * as crypto from "crypto";

// Helper to determine variant based on user ID (deterministic)
function getVariantForUser(userId: string, test: any): string {
    const hash = crypto.createHash("sha256").update(userId + test.testId).digest("hex");
    const intVal = parseInt(hash.substring(0, 8), 16);
    const index = intVal % test.variants.length;
    return test.variants[index].variantId;
}

/**
 * Sends a chat message notification to a user.
 *
 * Args:
 * - recipientUserId: string
 * - senderName: string
 * - messageBody: string
 * - chatRoomId: string
 */
export const sendNotification = functions.https.onCall(async (data, context) => {
    // Verify authentication
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "The function must be called while authenticated."
        );
    }

    const { recipientUserId, senderName, messageBody, chatRoomId } = data;

    if (!recipientUserId || !senderName || !messageBody || !chatRoomId) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Missing required arguments: recipientUserId, senderName, messageBody, chatRoomId."
        );
    }

    try {
        // 1. Get recipient's FCM token
        const userDoc = await admin.firestore().collection("users").doc(recipientUserId).get();

        if (!userDoc.exists) {
            console.log(`User ${recipientUserId} not found.`);
            return { success: false, error: "User not found" };
        }

        const userData = userDoc.data();
        const fcmToken = userData?.fcmToken;

        // Also check if user has notifications enabled
        const newMessageNotificationEnabled = userData?.newMessageNotification ?? true;

        if (!newMessageNotificationEnabled) {
             console.log(`User ${recipientUserId} has disabled message notifications.`);
             return { success: false, error: "Notifications disabled" };
        }

        if (!fcmToken) {
            console.log(`User ${recipientUserId} has no FCM token.`);
            return { success: false, error: "No FCM token" };
        }

        // 2. Prepare Notification Content (using A/B testing logic)
        // Determine variant for the recipient
        const variantId = getVariantForUser(recipientUserId, newMessageTest);

        // Truncate message preview to 20 chars
        const messagePreview = messageBody.length > 20
            ? messageBody.substring(0, 20) + "..."
            : messageBody;

        const { title, body } = getNotificationCopy(
            newMessageTest.testId,
            variantId,
            {
                userName: senderName,
                messagePreview: messagePreview,
            }
        );

        // 3. Send Message
        const message = {
            token: fcmToken,
            notification: {
                title: title,
                body: body,
            },
            data: {
                type: "chat", // Used for client-side routing
                chatRoomId: chatRoomId,
                senderId: context.auth.uid,
                click_action: "FLUTTER_NOTIFICATION_CLICK",
            },
            android: {
                priority: "high" as const, // Fix for TypeScript error on 'high' string
                notification: {
                    channelId: "high_importance_channel",
                    priority: "high" as const,
                },
            },
            apns: {
                payload: {
                    aps: {
                        sound: "default",
                        contentAvailable: true,
                    },
                },
            },
        };

        const response = await admin.messaging().send(message);
        console.log("Successfully sent message:", response);

        // 4. Log stats (optional, mimicking NotificationABService logic)
        await admin.firestore().collection("notification_stats").add({
            notificationId: response.split("/").pop(), // Extract ID from projects/.../messages/ID
            testId: newMessageTest.testId,
            variantId: variantId,
            userId: recipientUserId,
            type: "sent",
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });

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
