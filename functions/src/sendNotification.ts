import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

/**
 * Cloud Function to send a push notification to a specific user.
 * Can be called directly from the client or other backend services.
 *
 * Args:
 * - targetUserId: string (Required) - The ID of the user to notify.
 * - title: string (Required) - The notification title.
 * - body: string (Required) - The notification body.
 * - imageUrl: string (Optional) - URL for an image attachment.
 * - data: Record<string, string> (Optional) - Custom data payload.
 */
export const sendNotification = functions.https.onCall(async (data, context) => {
  // 1. Verify Authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  const {targetUserId, title, body, imageUrl, data: customData} = data;

  // Validate required fields
  if (!targetUserId || !title || !body) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "targetUserId, title, and body are required."
    );
  }

  try {
    // 2. Get target user's FCM token
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
      console.log(`User ${targetUserId} has no FCM token.`);
      return {success: false, reason: "no-token"};
    }

    // 3. Send Notification
    const message: admin.messaging.Message = {
      notification: {
        title,
        body,
        ...(imageUrl && {imageUrl}),
      },
      data: customData || {},
      token: fcmToken,
    };

    const messageId = await admin.messaging().send(message);

    console.log(`Successfully sent notification to user ${targetUserId}, messageId: ${messageId}`);

    return {success: true, messageId};
  } catch (error) {
    console.error("Error sending notification:", error);
    throw new functions.https.HttpsError(
      "internal",
      "Failed to send notification.",
      error
    );
  }
});
