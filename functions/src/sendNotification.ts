import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Ensure Firebase Admin is initialized.
// It might be initialized in index.ts or other files, but good practice to check/init if needed.
if (admin.apps.length === 0) {
  admin.initializeApp();
}

/**
 * Cloud Function to send a notification to a specific user.
 *
 * Usage:
 * call({
 *   targetUserId: "uid123",
 *   title: "New Message",
 *   body: "You have a new message from Alice",
 *   data: { type: "chat", chatId: "abc" }, // optional
 *   imageUrl: "https://..." // optional
 * })
 */
export const sendNotification = functions.https.onCall(async (data, context) => {
  // 1. Verify user identity
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  // Check if user is an admin
  const adminDoc = await admin.firestore()
    .collection("admins")
    .doc(context.auth.uid)
    .get();

  if (!adminDoc.exists) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Only admins can send notifications."
    );
  }

  const {targetUserId, title, body, data: customData, imageUrl} = data;

  // Validate required fields
  if (!targetUserId || !title || !body) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "The function must be called with arguments \"targetUserId\", \"title\", and \"body\"."
    );
  }

  try {
    // 2. Fetch target user's FCM token
    const userDoc = await admin.firestore().collection("users").doc(targetUserId).get();

    if (!userDoc.exists) {
      throw new functions.https.HttpsError(
        "not-found",
        `Target user ${targetUserId} not found.`
      );
    }

    const userData = userDoc.data();
    const fcmToken = userData?.fcmToken;

    if (!fcmToken) {
      console.log(`User ${targetUserId} has no FCM token. Notification skipped.`);
      return {
        success: false,
        reason: "no_token",
        message: "User has no FCM token registered.",
      };
    }

    // 3. Send notification
    const message: admin.messaging.Message = {
      token: fcmToken,
      notification: {
        title,
        body,
        ...(imageUrl && {imageUrl}),
      },
      data: customData || {},
    };

    const response = await admin.messaging().send(message);
    console.log(`Successfully sent notification to user ${targetUserId}, messageId: ${response}`);

    return {
      success: true,
      messageId: response,
    };
  } catch (error) {
    console.error("Error in sendNotification:", error);

    // Handle specific error codes if needed, e.g., invalid token
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    if ((error as any).code === "messaging/registration-token-not-registered") {
      return {
        success: false,
        reason: "invalid_token",
        message: "The registered token is no longer valid.",
      };
    }

    throw new functions.https.HttpsError(
      "internal",
      "Failed to send notification.",
      error
    );
  }
});
