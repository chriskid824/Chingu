import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Initialize admin if not already initialized
if (admin.apps.length === 0) {
  admin.initializeApp();
}

/**
 * Cloud Function to send a notification to a specific user.
 *
 * Args:
 * - targetUserId: The ID of the user to send the notification to.
 * - title: The notification title.
 * - body: The notification body.
 * - imageUrl: (Optional) URL of an image to include in the notification.
 * - data: (Optional) Custom data payload.
 */
export const sendNotification = functions.https.onCall(async (data, context) => {
  // 1. Verify user identity
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  const { targetUserId, title, body, imageUrl, data: customData } = data;

  // Validate input
  if (!targetUserId || !title || !body) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "targetUserId, title, and body are required."
    );
  }

  try {
    // 2. Get target user FCM Tokens
    const userDoc = await admin.firestore().collection("users").doc(targetUserId).get();

    if (!userDoc.exists) {
        throw new functions.https.HttpsError(
            "not-found",
            `User with ID ${targetUserId} not found.`
        );
    }

    const userData = userDoc.data();
    const fcmToken = userData?.fcmToken;

    if (!fcmToken) {
         // Return success: false but do not throw error as this is a valid state
         return { success: false, message: "User has no FCM token registered." };
    }

    // 3. Send notification
    const message: admin.messaging.Message = {
      token: fcmToken,
      notification: {
        title,
        body,
        ...(imageUrl && { imageUrl }),
      },
      data: customData || {},
    };

    const response = await admin.messaging().send(message);

    return { success: true, messageId: response };

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
