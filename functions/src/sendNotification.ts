import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

/**
 * Cloud Function for sending a notification to a specific user
 *
 * Usage:
 * - targetUserId: "uid123"
 * - title: "New Message"
 * - body: "Hello there!"
 * - data: { type: "chat", chatId: "abc" }
 * - imageUrl: "https://..."
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
    // Fetch target user's FCM token
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
      // User has no token, maybe they are not logged in on any device
      console.log(`User ${targetUserId} has no FCM token.`);
      return {success: false, reason: "no_token"};
    }

    const message: admin.messaging.Message = {
      notification: {
        title: title,
        body: body,
        ...(imageUrl && {imageUrl}),
      },
      data: customData || {},
      token: fcmToken,
    };

    const response = await admin.messaging().send(message);
    console.log(`Successfully sent notification to user ${targetUserId}:`, response);

    return {success: true, messageId: response};
  } catch (error) {
    console.error("Error sending notification:", error);
    throw new functions.https.HttpsError(
      "internal",
      "Failed to send notification.",
      error
    );
  }
});
