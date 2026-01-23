import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

/**
 * Sends a chat notification to a specific user.
 *
 * Data payload:
 * - token: string (FCM token of the recipient)
 * - title: string (Notification title, typically sender's name)
 * - body: string (Notification body, typically message content)
 * - data: Record<string, string> (Optional custom data)
 */
export const sendChatNotification = functions.https.onCall(async (data, context) => {
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
      "The function must be called with argument 'token', 'title' and 'body'."
    );
  }

  const message: admin.messaging.Message = {
    token: token,
    notification: {
      title: title,
      body: body,
    },
    data: customData || {},
  };

  try {
    const response = await admin.messaging().send(message);
    return { success: true, messageId: response };
  } catch (error) {
    console.error("Error sending notification:", error);
    throw new functions.https.HttpsError("internal", "Error sending notification", error);
  }
});
