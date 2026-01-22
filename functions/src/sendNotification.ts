import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Ensure app is initialized
if (admin.apps.length === 0) {
  admin.initializeApp();
}

/**
 * Cloud Function to send a push notification to a specific device.
 *
 * Payload:
 * - token: The FCM token of the recipient device.
 * - title: The title of the notification.
 * - body: The body text of the notification.
 * - data: Optional custom data payload (Map<String, String>).
 */
export const sendNotification = functions.https.onCall(async (data, context) => {
  // Check if user is authenticated (optional, but good practice)
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  const { token, title, body, data: customData } = data;

  if (!token || !title || !body) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "The function must be called with arguments 'token', 'title', and 'body'."
    );
  }

  const message = {
    token: token,
    notification: {
      title: title,
      body: body,
    },
    data: customData || {},
  };

  try {
    await admin.messaging().send(message);
    return { success: true };
  } catch (error) {
    console.error("Error sending notification:", error);
    throw new functions.https.HttpsError(
      "internal",
      "Error sending notification",
      error
    );
  }
});
