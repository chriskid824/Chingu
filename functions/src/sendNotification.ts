import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

/**
 * Cloud Function to send a push notification to a specific user.
 *
 * Args:
 * - recipientId: String (Target user ID)
 * - title: String (Notification title)
 * - body: String (Notification body)
 * - data: Map<String, dynamic> (Optional data payload)
 */
export const sendNotification = functions.https.onCall(async (data, context) => {
  // 1. Authenticate user
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  const { recipientId, title, body, data: customData } = data;

  // 2. Validate arguments
  if (!recipientId || !title || !body) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "recipientId, title, and body are required."
    );
  }

  try {
    // 3. Get recipient's FCM token
    const userDoc = await admin.firestore().collection("users").doc(recipientId).get();

    if (!userDoc.exists) {
      throw new functions.https.HttpsError(
        "not-found",
        "Recipient user not found."
      );
    }

    const userData = userDoc.data();
    const fcmToken = userData?.fcmToken;

    if (!fcmToken) {
      // User has no token, just return without erroring (maybe they logged out)
      console.log(`User ${recipientId} has no FCM token.`);
      return { success: false, reason: "no_token" };
    }

    // 4. Send notification
    const message = {
      notification: {
        title: title,
        body: body,
      },
      data: customData || {},
      token: fcmToken,
    };

    const response = await admin.messaging().send(message);
    console.log("Successfully sent message:", response);

    return { success: true, messageId: response };

  } catch (error) {
    console.error("Error sending notification:", error);
    throw new functions.https.HttpsError(
      "internal",
      "Error sending notification",
      error
    );
  }
});
