import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Ensure admin is initialized (it might be initialized in index.ts or other files, but safe to do here if not)
if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Cloud Function to send a push notification to a specific user.
 *
 * Arguments:
 * - targetUserId: string (Required) - The UID of the recipient.
 * - title: string (Required) - Notification title (e.g., Sender Name).
 * - body: string (Required) - Notification body (e.g., Message preview).
 * - data: map (Optional) - Custom data payload.
 */
export const sendNotification = functions.https.onCall(async (data, context) => {
    // Verify authentication
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "The function must be called while authenticated."
        );
    }

    const { targetUserId, title, body, data: customData } = data;

    // Validate inputs
    if (!targetUserId || !title || !body) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "The function must be called with 'targetUserId', 'title', and 'body'."
        );
    }

    try {
        // Fetch the target user's FCM token
        const userDoc = await admin.firestore().collection("users").doc(targetUserId).get();

        if (!userDoc.exists) {
            throw new functions.https.HttpsError(
                "not-found",
                `User ${targetUserId} does not exist.`
            );
        }

        const userData = userDoc.data();
        const fcmToken = userData?.fcmToken;

        if (!fcmToken) {
            console.log(`User ${targetUserId} does not have an FCM token.`);
            return { success: false, message: "User has no FCM token." };
        }

        // Construct the message
        const message: admin.messaging.Message = {
            token: fcmToken,
            notification: {
                title: title,
                body: body,
            },
            data: customData || {},
            android: {
                notification: {
                    clickAction: "FLUTTER_NOTIFICATION_CLICK",
                },
            },
            apns: {
                payload: {
                    aps: {
                        alert: {
                            title: title,
                            body: body,
                        },
                        sound: "default",
                    },
                },
            },
        };

        // Send the message
        const messageId = await admin.messaging().send(message);
        console.log(`Successfully sent message to ${targetUserId}: ${messageId}`);

        return { success: true, messageId: messageId };

    } catch (error) {
        console.error("Error sending notification:", error);
        throw new functions.https.HttpsError(
            "internal",
            "Unable to send notification.",
            error
        );
    }
});
