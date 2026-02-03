import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Cloud Function to send a notification to a specific user
 *
 * Usage:
 * - targetUserId: string (required)
 * - title: string (required)
 * - body: string (required)
 * - data: object (must include chatRoomId for security)
 * - imageUrl: string (optional)
 */
export const sendNotification = functions.https.onCall(async (data, context) => {
    // Verify authentication
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "The function must be called while authenticated."
        );
    }

    const {
        targetUserId,
        title,
        body,
        data: customData,
        imageUrl,
    } = data;

    // Validate required fields
    if (!targetUserId || !title || !body) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "targetUserId, title, and body are required."
        );
    }

    try {
        // Security Check: Verify Chat Room Participation
        // We require chatRoomId to be present in data to verify relationship
        const chatRoomId = customData?.chatRoomId;
        if (!chatRoomId) {
             throw new functions.https.HttpsError(
                "invalid-argument",
                "chatRoomId is required in data for security verification."
            );
        }

        const chatRoomDoc = await admin.firestore().collection("chat_rooms").doc(chatRoomId).get();
        if (!chatRoomDoc.exists) {
             throw new functions.https.HttpsError(
                "not-found",
                "Chat room not found."
            );
        }

        const participants = chatRoomDoc.data()?.participantIds || [];
        const senderId = context.auth.uid;

        // Check if both sender and receiver are in the chat room
        if (!participants.includes(senderId)) {
             throw new functions.https.HttpsError(
                "permission-denied",
                "Sender is not a participant in this chat room."
            );
        }

        if (!participants.includes(targetUserId)) {
             throw new functions.https.HttpsError(
                "permission-denied",
                "Target user is not a participant in this chat room."
            );
        }

        // Fetch the target user's FCM token
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
            console.log(`User ${targetUserId} has no FCM token. Skipping notification.`);
            return { success: false, reason: "no_token" };
        }

        // Construct the message
        const message = {
            notification: {
                title: title,
                body: body,
                ...(imageUrl && { imageUrl }),
            },
            data: customData || {},
            token: fcmToken,
        };

        // Send the message
        const response = await admin.messaging().send(message);
        console.log(`Successfully sent message to user ${targetUserId}:`, response);

        return { success: true, messageId: response };
    } catch (error) {
        console.error("Error sending notification:", error);
        // Re-throw HttpsError as is
        if (error instanceof functions.https.HttpsError) {
            throw error;
        }
        throw new functions.https.HttpsError(
            "internal",
            "Failed to send notification.",
            error
        );
    }
});
