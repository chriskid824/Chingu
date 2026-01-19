import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Ensure firebase-admin is initialized.
if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Cloud Function to send a notification to a specific user.
 *
 * Arguments:
 * - userId: The UID of the recipient.
 * - title: Notification title.
 * - body: Notification body.
 * - data: (Optional) Custom data payload.
 * - imageUrl: (Optional) URL of the image to display.
 */
export const sendNotification = functions.https.onCall(async (data, context) => {
    // 1. Authentication Check
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "The function must be called while authenticated."
        );
    }

    const { userId, title, body, data: customData, imageUrl } = data;
    const callerId = context.auth.uid;

    // 2. Validation
    if (!userId || !title || !body) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "The function must be called with arguments 'userId', 'title', and 'body'."
        );
    }

    // 3. Security Check: Prevent Open Relay
    // Only allow users to send notifications to others if they are connected.
    // Case 1: Match Notification (Chat Room)
    if (customData && customData.type === 'match_success' && customData.actionData) {
        const chatRoomId = customData.actionData;
        try {
            const chatRoomDoc = await admin.firestore().collection("chat_rooms").doc(chatRoomId).get();
            if (!chatRoomDoc.exists) {
                console.warn(`Caller ${callerId} tried to send match notification with invalid chatRoomId ${chatRoomId}`);
                throw new functions.https.HttpsError("permission-denied", "Invalid chat room.");
            }

            const participants = chatRoomDoc.data()?.participantIds || [];
            if (!participants.includes(callerId)) {
                console.warn(`Caller ${callerId} tried to send notification for chat room ${chatRoomId} they are not in.`);
                throw new functions.https.HttpsError("permission-denied", "You are not a participant in this match.");
            }

            // Optionally check if target userId is also in participants
            if (!participants.includes(userId)) {
                 console.warn(`Caller ${callerId} tried to send notification to ${userId} who is not in chat room ${chatRoomId}.`);
                 throw new functions.https.HttpsError("permission-denied", "Target user is not in this match.");
            }

        } catch (e) {
            console.error("Error validating chat room access:", e);
             // Re-throw if it's already an HttpsError, otherwise wrap it
             if (e instanceof functions.https.HttpsError) {
                throw e;
             }
             throw new functions.https.HttpsError("internal", "Error validating permission.");
        }
    } else {
        // For other types, currently restrict to sending to self (e.g. testing)
        // OR require admin privileges (not implemented here for simplicity, but good practice).
        // Since the prompt is about match notifications, we enforce the check above.
        // If we want to allow generic notifications, we should probably restrict it.
        // For now, if it's NOT a match notification, we'll block it unless it's to self.

        if (userId !== callerId) {
             console.warn(`Caller ${callerId} tried to send generic notification to ${userId} without permission.`);
             throw new functions.https.HttpsError("permission-denied", "You can only send generic notifications to yourself.");
        }
    }

    try {
        // 4. Get User's FCM Token
        const userDoc = await admin.firestore().collection("users").doc(userId).get();
        if (!userDoc.exists) {
            throw new functions.https.HttpsError("not-found", "Target user not found.");
        }

        const userData = userDoc.data();
        const fcmToken = userData?.fcmToken;

        if (!fcmToken) {
            console.log(`User ${userId} does not have an FCM token. Skipping notification.`);
            return { success: false, reason: "no-fcm-token" };
        }

        // 5. Construct Message
        const message: admin.messaging.Message = {
            token: fcmToken,
            notification: {
                title: title,
                body: body,
                ...(imageUrl && { imageUrl }),
            },
            data: customData || {},
        };

        // 6. Send Message
        const messageId = await admin.messaging().send(message);
        console.log(`Successfully sent message to user ${userId}: ${messageId}`);

        return { success: true, messageId };

    } catch (error) {
        console.error("Error sending notification:", error);
        throw new functions.https.HttpsError(
            "internal",
            "Unable to send notification.",
            error
        );
    }
});
