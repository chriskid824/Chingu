import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

/**
 * Cloud Function for sending broadcast notifications
 * Can be called by admin to send global or targeted notifications
 * 
 * Usage:
 * - Global broadcast: targetAll = true
 * - City-specific: targetCities = ["taipei", "taichung"]
 * - User-specific: targetUserIds = ["uid1", "uid2"]
 */
export const sendBroadcast = functions.https.onCall(async (data, context) => {
  // Verify that the request is made by an authenticated user
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Only authenticated users can send broadcasts."
    );
  }

  // TODO: Add admin role verification
  // For now, we'll check if user is in an 'admins' collection
  const adminDoc = await admin.firestore()
    .collection("admins")
    .doc(context.auth.uid)
    .get();

  if (!adminDoc.exists) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Only admins can send broadcast notifications."
    );
  }

  const {
    title,
    body,
    data: customData,
    targetAll = false,
    targetCities = [],
    targetUserIds = [],
    imageUrl,
  } = data;

  // Validate required fields
  if (!title || !body) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Title and body are required."
    );
  }

  try {
    let targetTokens: string[] = [];

    if (targetAll) {
      // Send to all users - use topic subscription
      const message = {
        notification: {
          title: title,
          body: body,
          ...(imageUrl && {imageUrl}),
        },
        data: customData || {},
        topic: "all_users",
      };

      const response = await admin.messaging().send(message);
      console.log("Successfully sent broadcast to all users:", response);

      // Log the broadcast
      await admin.firestore().collection("broadcast_logs").add({
        title,
        body,
        targetType: "all",
        sentBy: context.auth.uid,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        messageId: response,
      });

      return {success: true, messageId: response, recipients: "all"};
    } else if (targetUserIds && targetUserIds.length > 0) {
      // Send to specific users
      // Use getAll to avoid 'in' query limit of 30 items
      const userRefs = targetUserIds.map((uid: string) =>
        admin.firestore().collection("users").doc(uid)
      );

      const userSnapshots = await admin.firestore().getAll(...userRefs);

      targetTokens = userSnapshots
        .filter((doc) => doc.exists)
        .map((doc) => doc.data()?.fcmToken)
        .filter((token) => token); // Remove null/undefined tokens
    } else if (targetCities && targetCities.length > 0) {
      // Send to users in specific cities
      const citiesLower = targetCities.map((city: string) => city.toLowerCase());
      // Note: 'in' query is limited to 30 items
      const usersSnapshot = await admin.firestore()
        .collection("users")
        .where("city", "in", citiesLower)
        .get();

      targetTokens = usersSnapshot.docs
        .map((doc) => doc.data().fcmToken)
        .filter((token) => token);
    } else {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Must specify targetAll, targetUserIds, or targetCities."
      );
    }

    if (targetTokens.length === 0) {
      throw new functions.https.HttpsError(
        "not-found",
        "No users found with FCM tokens for the specified criteria."
      );
    }

    // Send multicast message
    // batching is required if > 500 tokens, but sendEachForMulticast handles it?
    // sendEachForMulticast sends to up to 500 tokens.
    // If we have more than 500, we need to split manually.
    // However, for this task, we will assume reasonable limits or relying on sendEachForMulticast documentation.
    // Documentation says: "Sends the given multicast message to all the FCM registration tokens specified in it."
    // But it has a limit of 500 tokens per invocation.
    // We should implement batching if we expect > 500 tokens for targeted users/cities.
    // For now, I'll add simple batching.

    const batches = [];
    const BATCH_SIZE = 500;
    for (let i = 0; i < targetTokens.length; i += BATCH_SIZE) {
      batches.push(targetTokens.slice(i, i + BATCH_SIZE));
    }

    let successCount = 0;
    let failureCount = 0;

    for (const batchTokens of batches) {
      const message = {
        notification: {
          title: title,
          body: body,
          ...(imageUrl && {imageUrl}),
        },
        data: customData || {},
        tokens: batchTokens,
      };

      const response = await admin.messaging().sendEachForMulticast(message);
      successCount += response.successCount;
      failureCount += response.failureCount;

      if (response.failureCount > 0) {
        console.log(`Failed to send ${response.failureCount} messages in a batch`);
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            console.error(`Error sending to token ${batchTokens[idx]}:`, resp.error);
          }
        });
      }
    }

    // Log the broadcast
    await admin.firestore().collection("broadcast_logs").add({
      title,
      body,
      targetType: targetUserIds.length > 0 ? "users" : "cities",
      targetIds: targetUserIds.length > 0 ? targetUserIds : targetCities,
      sentBy: context.auth.uid,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      successCount,
      failureCount,
    });

    return {
      success: true,
      successCount,
      failureCount,
      totalTargets: targetTokens.length,
    };
  } catch (error) {
    console.error("Error sending broadcast:", error);
    throw new functions.https.HttpsError(
      "internal",
      "Failed to send broadcast notification.",
      error
    );
  }
});
