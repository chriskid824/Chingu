import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Ensure admin is initialized (if not already by index or other files)
if (admin.apps.length === 0) {
  admin.initializeApp();
}

/**
 * Cloud Function for sending targeted notifications
 * Can be called by authenticated users to send notifications to specific users
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
    data: customData,
  } = data;

  // Validate required fields
  if (!targetUserId || !title || !body) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Target user ID, title, and body are required."
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
      // We return success: false instead of throwing error to avoid client crashing if they just want to try sending
      // But usually APIs throw errors. The prompt says "Get target user FCM Tokens".
      // If token is missing, we can't send.
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Target user does not have a registered FCM token."
      );
    }

    // Construct message
    const message: admin.messaging.Message = {
      notification: {
        title,
        body,
        ...(imageUrl && {imageUrl}),
      },
      data: customData || {},
      token: fcmToken,
    };

    // Send message
    const response = await admin.messaging().send(message);
    console.log(`Successfully sent notification to user ${targetUserId}:`, response);

    return {
      success: true,
      messageId: response,
    };
  } catch (error) {
    console.error("Error sending notification:", error);
    // Re-throw HttpsError if it's already one, otherwise wrap it
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
