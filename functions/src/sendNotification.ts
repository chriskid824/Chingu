import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
    admin.initializeApp();
}

interface SendNotificationData {
    targetUserId: string;
    title: string;
    body: string;
    imageUrl?: string;
    data?: { [key: string]: string };
}

/**
 * Cloud Function to send a notification to a specific user
 * Verifies user identity and uses FCM Admin SDK
 */
export const sendNotification = functions.https.onCall(async (data: SendNotificationData, context) => {
    // Verify that the request is made by an authenticated user
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "Only authenticated users can send notifications."
        );
    }

    const { targetUserId, title, body, imageUrl, data: customData } = data;

    // Validate required fields
    if (!targetUserId || !title || !body) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "targetUserId, title, and body are required."
        );
    }

    try {
        // Fetch target user's FCM token
        const userDoc = await admin.firestore().collection("users").doc(targetUserId).get();

        if (!userDoc.exists) {
            throw new functions.https.HttpsError(
                "not-found",
                "Target user not found."
            );
        }

        const userData = userDoc.data();
        const fcmToken = userData?.fcmToken;

        if (!fcmToken) {
            // It's possible the user exists but has no token (e.g. hasn't allowed notifications)
            // We can treat this as a success but with a note, or an error.
            // Usually treating as error or returning a specific status is better.
            console.warn(`User ${targetUserId} has no FCM token.`);
            throw new functions.https.HttpsError(
                "failed-precondition",
                "Target user does not have a valid FCM token."
            );
        }

        // Construct the message
        const message: admin.messaging.Message = {
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
        console.log(`Successfully sent notification to user ${targetUserId}, messageId: ${response}`);

        return {
            success: true,
            messageId: response,
        };

    } catch (error) {
        console.error("Error sending notification:", error);
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
