import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Ensure app is initialized only once
if (admin.apps.length === 0) {
  admin.initializeApp();
}

/**
 * Cloud Function to send a notification to a specific user.
 *
 * Input data:
 * - targetUserId: string (required)
 * - title: string (required)
 * - body: string (required)
 * - data: Record<string, string> (optional)
 * - imageUrl: string (optional)
 */
export const sendNotification = functions.https.onCall(async (data, context) => {
  // 1. Verify User Identity
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  const {targetUserId, title, body, data: customData, imageUrl} = data;

  // Validate required fields
  if (!targetUserId || !title || !body) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "targetUserId, title, and body are required."
    );
  }

  try {
    // 2. Fetch Target User's FCM Token
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
      console.log(`User ${targetUserId} does not have an FCM token.`);
      // We don't throw an error here to avoid crashing the caller, just return failure
      return {
        success: false,
        reason: "no-token",
      };
    }

    // 3. Send Notification using FCM Admin SDK
    const message: admin.messaging.Message = {
      token: fcmToken,
      notification: {
        title: title,
        body: body,
        ...(imageUrl && {imageUrl}),
      },
      data: customData || {},
    };

    const response = await admin.messaging().send(message);
    console.log("Successfully sent message:", response);

    return {
      success: true,
      messageId: response,
    };
  } catch (error) {
    console.error("Error sending notification:", error);
    throw new functions.https.HttpsError(
      "internal",
      "Failed to send notification.",
      error
    );
  }
});
