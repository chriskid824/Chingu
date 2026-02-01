import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (!admin.apps.length) {
  admin.initializeApp();
}

/**
 * Cloud Function to send FCM notification.
 *
 * Logic:
 * 1. Verify Authentication (context.auth)
 * 2. Get target FCM token (from input 'token' or by fetching user 'targetUserId')
 * 3. Send notification using admin.messaging().send()
 */
export const sendNotification = functions.https.onCall(async (data, context) => {
  // 1. Verify Identity
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  const {token, targetUserId, title, body, imageUrl, data: customData} = data;

  // Validate required content
  if (!title || !body) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Title and body are required."
    );
  }

  let targetToken = token;

  // 2. Get Target Token
  if (!targetToken) {
    if (targetUserId) {
      // Fetch from Firestore
      try {
        const userDoc = await admin.firestore().collection("users").doc(targetUserId).get();
        if (userDoc.exists) {
          const userData = userDoc.data();
          targetToken = userData?.fcmToken;
        } else {
          throw new functions.https.HttpsError(
            "not-found",
            `User ${targetUserId} not found.`
          );
        }
      } catch (error) {
        console.error("Error fetching user:", error);
        throw new functions.https.HttpsError(
          "internal",
          "Error fetching target user."
        );
      }
    } else {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Either 'token' or 'targetUserId' must be provided."
      );
    }
  }

  if (!targetToken) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Target user has no FCM token."
    );
  }

  // 3. Send Notification
  const message: admin.messaging.Message = {
    token: targetToken,
    notification: {
      title,
      body,
      ...(imageUrl && {imageUrl}),
    },
    data: customData || {},
  };

  try {
    const response = await admin.messaging().send(message);
    console.log("Successfully sent message:", response);
    return {success: true, messageId: response};
  } catch (error) {
    console.error("Error sending message:", error);
    throw new functions.https.HttpsError(
      "internal",
      "Error sending notification.",
      error
    );
  }
});
