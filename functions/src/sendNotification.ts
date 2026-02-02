import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Ensure firebase app is initialized
if (admin.apps.length === 0) {
  admin.initializeApp();
}

interface SendNotificationData {
  targetUserId: string;
  title: string;
  body: string;
  data?: Record<string, string>;
}

export const sendNotification = functions.https.onCall(async (data: SendNotificationData, context) => {
  // Authentication check
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  const {targetUserId, title, body, data: payloadData} = data;

  if (!targetUserId || !title || !body) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "The function must be called with targetUserId, title, and body."
    );
  }

  try {
    const userDoc = await admin.firestore().collection("users").doc(targetUserId).get();
    if (!userDoc.exists) {
      console.log(`User ${targetUserId} not found.`);
      return {success: false, message: "User not found"};
    }

    const userData = userDoc.data();
    const fcmToken = userData?.fcmToken;

    if (!fcmToken) {
      console.log(`User ${targetUserId} has no FCM token.`);
      return {success: false, message: "No FCM token for user"};
    }

    // Check if push is enabled
    const notificationSettings = userData?.notificationSettings || {};
    // Default to true if not set, or false if explicitly false? Usually default is true.
    // However, if the field is missing, we assume true. If it is false, we respect it.
    if (notificationSettings.pushEnabled === false) {
      console.log(`User ${targetUserId} has disabled push notifications.`);
      return {success: false, message: "Push notifications disabled by user"};
    }

    const message: admin.messaging.Message = {
      token: fcmToken,
      notification: {
        title: title,
        body: body,
      },
      data: payloadData || {},
    };

    await admin.messaging().send(message);
    console.log(`Notification sent to ${targetUserId}.`);
    return {success: true};
  } catch (error) {
    console.error("Error sending notification:", error);
    throw new functions.https.HttpsError("internal", "Error sending notification");
  }
});
