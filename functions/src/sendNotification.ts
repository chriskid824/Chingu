import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Ensure Firebase Admin is initialized
if (admin.apps.length === 0) {
    admin.initializeApp();
}

interface SendNotificationData {
    targetUserId: string;
    title: string;
    body: string;
    imageUrl?: string;
    type?: string;
    data?: Record<string, string>;
}

export const sendNotification = functions.https.onCall(async (data: SendNotificationData, context) => {
    // Verify that the request is made by an authenticated user
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "Only authenticated users can send notifications."
        );
    }

    const { targetUserId, title, body, imageUrl, type, data: customData } = data;

    // Validate required fields
    if (!targetUserId || !title || !body) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Target User ID, Title, and Body are required."
        );
    }

    try {
        // Fetch the target user's FCM token
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
            throw new functions.https.HttpsError(
                "failed-precondition",
                "Target user does not have a registered FCM token."
            );
        }

        // Construct the message payload
        const message: admin.messaging.Message = {
            token: fcmToken,
            notification: {
                title: title,
                body: body,
                ...(imageUrl && { imageUrl }),
            },
            data: {
                ...customData,
                ...(type && { type }),
            },
        };

        // Send the message
        const messageId = await admin.messaging().send(message);

        console.log(`Successfully sent notification to user ${targetUserId}: ${messageId}`);

        return { success: true, messageId: messageId };

    } catch (error) {
        console.error("Error sending notification:", error);

        // Re-throw HTTPS errors
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
