import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Ensure app is initialized
if (admin.apps.length === 0) {
  admin.initializeApp();
}

/**
 * Send a notification to a specific device via FCM.
 * Callable from the client.
 */
export const sendNotification = functions.https.onCall(async (data, context) => {
  // 1. Authentication Check
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Only authenticated users can send notifications."
    );
  }

  const { token, title, body, data: customData } = data;

  // 2. Validation
  if (!token || !title || !body) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "The function must be called with 'token', 'title', and 'body'."
    );
  }

  try {
    // 3. Construct Message
    const message: admin.messaging.Message = {
      token: token,
      notification: {
        title: title,
        body: body,
      },
      data: customData || {},
    };

    // 4. Send
    const response = await admin.messaging().send(message);
    console.log("Successfully sent message:", response);
    return { success: true, messageId: response };
  } catch (error) {
    console.error("Error sending notification:", error);
    throw new functions.https.HttpsError(
      "internal",
      "Unable to send notification",
      error
    );
  }
});
