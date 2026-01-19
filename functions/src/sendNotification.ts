import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

/**
 * Cloud Function to send a notification to a specific user
 * respecting their notification preferences.
 */
export const sendNotification = functions.https.onCall(async (data, context) => {
  // Check authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Only authenticated users/systems can send notifications."
    );
  }

  const {
    userId,
    title,
    body,
    type = 'system', // 'newMatch', 'matchSuccess', 'newMessage', etc.
    data: customData,
    imageUrl,
  } = data;

  if (!userId || !title || !body) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "userId, title, and body are required."
    );
  }

  try {
    // 1. Fetch target user
    const userDoc = await admin.firestore().collection("users").doc(userId).get();

    if (!userDoc.exists) {
        throw new functions.https.HttpsError("not-found", "User not found");
    }

    const userData = userDoc.data();
    if (!userData) {
        throw new functions.https.HttpsError("not-found", "User data empty");
    }

    // 2. Check Preferences
    // Default to true if preference is missing, unless global notification is off?
    // Let's check global switch if we had one, but we have individual switches.
    // If specific preference is explicitly false, don't send.
    if (userData.notificationPreferences &&
        userData.notificationPreferences[type] === false) {
        console.log(`Notification suppressed due to preference: ${type} for user ${userId}`);
        return { success: false, reason: "preference_disabled" };
    }

    // 3. Get FCM Token
    const fcmToken = userData.fcmToken;
    if (!fcmToken) {
        console.log(`No FCM token for user ${userId}`);
        return { success: false, reason: "no_token" };
    }

    // 4. Send Notification
    const message = {
        notification: {
            title: title,
            body: body,
            ...(imageUrl && { imageUrl }),
        },
        data: {
            ...customData,
            notificationType: type,
        },
        token: fcmToken,
    };

    const response = await admin.messaging().send(message);
    console.log(`Successfully sent notification to ${userId}:`, response);

    return { success: true, messageId: response };

  } catch (error) {
    console.error("Error sending notification:", error);
    throw new functions.https.HttpsError(
      "internal",
      "Failed to send notification.",
      error
    );
  }
});
