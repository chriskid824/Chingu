import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

/**
 * Cloud Function to send a notification to a specific user or users.
 *
 * Usage:
 * - Single user: targetUserId = "uid1"
 * - Multiple users: targetUserIds = ["uid1", "uid2"]
 */
export const sendNotification = functions.https.onCall(async (data, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  const {
    targetUserId,
    targetUserIds,
    title,
    body,
    imageUrl,
    data: customData,
  } = data;

  // Validate inputs
  if ((!targetUserId && !targetUserIds) || !title || !body) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "targetUserId (or targetUserIds), title, and body are required."
    );
  }

  try {
    let targets: string[] = [];
    if (targetUserIds && Array.isArray(targetUserIds)) {
      targets = targetUserIds;
    } else if (targetUserId) {
      targets = [targetUserId];
    }

    if (targets.length === 0) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "No target users specified."
      );
    }

    // Fetch tokens
    const tokens: string[] = [];

    // Firestore 'in' query supports up to 10 values
    const chunks = [];
    const chunkSize = 10;
    for (let i = 0; i < targets.length; i += chunkSize) {
      chunks.push(targets.slice(i, i + chunkSize));
    }

    for (const chunk of chunks) {
      const snap = await admin.firestore()
        .collection("users")
        .where(admin.firestore.FieldPath.documentId(), "in", chunk)
        .get();

      snap.docs.forEach((doc) => {
        const token = doc.data().fcmToken;
        if (token) {
          tokens.push(token);
        }
      });
    }

    if (tokens.length === 0) {
      return {success: false, message: "No FCM tokens found for target user(s)."};
    }

    const messageBase = {
      notification: {
        title,
        body,
        ...(imageUrl && {imageUrl}),
      },
      data: customData || {},
    };

    if (tokens.length === 1) {
      const message = {
        ...messageBase,
        token: tokens[0],
      };
      const response = await admin.messaging().send(message);
      return {success: true, messageId: response};
    } else {
      const message = {
        ...messageBase,
        tokens: tokens,
      };
      const response = await admin.messaging().sendEachForMulticast(message);
      return {
        success: true,
        successCount: response.successCount,
        failureCount: response.failureCount,
      };
    }
  } catch (error) {
    console.error("Error sending notification:", error);
    throw new functions.https.HttpsError(
      "internal",
      "Failed to send notification.",
      error
    );
  }
});
