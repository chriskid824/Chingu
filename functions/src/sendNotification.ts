import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

/**
 * Sends a notification to a specific device using FCM token.
 * Expected data:
 * - token: string (Target FCM token)
 * - title: string (Notification title)
 * - body: string (Notification body)
 * - data: object (Optional custom data)
 */
export const sendNotification = functions.https.onCall(async (data, context) => {
  // 1. Verify Authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  const {token, title, body, data: customData} = data;

  // 2. Validate Input
  if (!token || typeof token !== "string") {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "The function must be called with a valid 'token' argument."
    );
  }
  if (!title || typeof title !== "string") {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "The function must be called with a valid 'title' argument."
    );
  }
  if (!body || typeof body !== "string") {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "The function must be called with a valid 'body' argument."
    );
  }

  // 3. Construct Message
  const message: admin.messaging.Message = {
    token: token,
    notification: {
      title: title,
      body: body,
    },
    data: customData || {},
  };

  try {
    // 4. Send Notification
    const response = await admin.messaging().send(message);
    console.log("Successfully sent message:", response);
    return {success: true, messageId: response};
  } catch (error) {
    console.error("Error sending message:", error);
    throw new functions.https.HttpsError(
      "internal",
      "Error sending notification",
      error
    );
  }
});
