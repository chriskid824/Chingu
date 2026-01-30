import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Ensure app is initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

interface SendNotificationData {
    recipientId: string;
    title: string;
    body: string;
    data?: Record<string, string>;
    imageUrl?: string;
}

/**
 * Cloud Function to send a push notification to a specific user.
 *
 * Usage:
 * Call this function with { recipientId, title, body, data?, imageUrl? }
 */
export const sendNotification = functions.https.onCall(async (data: SendNotificationData, context) => {
  // 1. Verify User Identity
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  const {recipientId, title, body, data: customData, imageUrl} = data;

  // Validate required fields
  if (!recipientId || !title || !body) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "The function must be called with argument { recipientId, title, body }."
    );
  }

  try {
    // 2. Get Target User FCM Tokens
    const userDoc = await admin.firestore().collection("users").doc(recipientId).get();

    if (!userDoc.exists) {
      throw new functions.https.HttpsError(
        "not-found",
        `User with ID ${recipientId} does not exist.`
      );
    }

    const userData = userDoc.data();
    const fcmToken = userData?.fcmToken;

    if (!fcmToken) {
      console.log(`User ${recipientId} has no FCM token. Notification skipped.`);
      return {success: false, message: "User has no FCM token."};
    }

    // 3. Send Notification using FCM Admin SDK
    // Construct notification object
    const notification = {
      title,
      body,
      ...(imageUrl && {imageUrl}),
    };

    let response;
    if (Array.isArray(fcmToken)) {
      // Handle multiple tokens
      const message = {
        notification,
        data: customData || {},
        tokens: fcmToken,
      };
      const multicastResponse = await admin.messaging().sendEachForMulticast(message);
      response = {
        successCount: multicastResponse.successCount,
        failureCount: multicastResponse.failureCount,
      };

      // Log failures if any
      if (multicastResponse.failureCount > 0) {
        console.log(`Failed to send to ${multicastResponse.failureCount} tokens for user ${recipientId}.`);
      }
    } else {
      // Handle single token
      const message = {
        notification,
        data: customData || {},
        token: fcmToken,
      };
      const messageId = await admin.messaging().send(message);
      response = {messageId};
    }

    console.log(`Successfully sent notification to user ${recipientId}.`, response);
    return {success: true, response};
  } catch (error) {
    console.error("Error sending notification:", error);
    throw new functions.https.HttpsError(
      "internal",
      "Error sending notification",
      error
    );
  }
});
