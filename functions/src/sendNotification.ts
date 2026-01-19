import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

/**
 * Cloud Function for sending a notification to a specific user.
 * Callable by authenticated users.
 *
 * Usage:
 * call sendNotification({
 *   targetUserId: "uid123",
 *   title: "New Message",
 *   body: "You have a new message!",
 *   data: { "type": "chat", "id": "chat123" },
 *   imageUrl: "https://example.com/image.png"
 * })
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
        `User ${targetUserId} not found.`
      );
    }

    const userData = userDoc.data();
    const fcmToken = userData?.fcmToken;

    if (!fcmToken) {
      // It's not necessarily an error if the user doesn't have a token (maybe they logged out)
      // But we can't send a notification.
      console.log(`User ${targetUserId} has no FCM token.`);
      return {
        success: false,
        reason: "no-token",
        message: "Target user has no FCM token.",
      };
    }

    // Prepare the message
    const message: admin.messaging.Message = {
      notification: {
        title: title,
        body: body,
        ...(imageUrl && {imageUrl}),
      },
      data: customData || {},
      token: fcmToken,
    };

    // Send the message
    const response = await admin.messaging().send(message);
    console.log(`Successfully sent notification to user ${targetUserId}:`, response);

    return {
      success: true,
      messageId: response,
    };
  } catch (error) {
    console.error("Error sending notification:", error);
    // If the error is already an HttpsError, re-throw it
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    // Otherwise throw an internal error
    throw new functions.https.HttpsError(
      "internal",
      "Failed to send notification.",
      error
    );
  }
});
