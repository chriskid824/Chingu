import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Initialize admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

export const sendChatNotification = functions.https.onCall(async (data, context) => {
  // Check if user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  const token = data.token;
  const title = data.title;
  const body = data.body;
  const notificationData = data.data || {};

  if (!token || !title || !body) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "The function must be called with arguments \"token\", \"title\", and \"body\"."
    );
  }

  const message = {
    token: token,
    notification: {
      title: title,
      body: body,
    },
    data: notificationData,
    android: {
      priority: "high" as const,
      notification: {
        sound: "default",
      },
    },
    apns: {
      payload: {
        aps: {
          sound: "default",
          badge: 1,
          contentAvailable: true,
        },
      },
    },
  };

  try {
    const response = await admin.messaging().send(message);
    return { success: true, messageId: response };
  } catch (error) {
    console.error("Error sending message:", error);
    throw new functions.https.HttpsError("internal", "Error sending message", error);
  }
});
