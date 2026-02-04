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
      // Chunk ids to groups of 10 for 'in' query
      const chunks = chunkArray(targetUserIds, 10);
      const promises = chunks.map((chunk) =>
        admin.firestore()
          .collection("users")
          .where(admin.firestore.FieldPath.documentId(), "in", chunk)
          .get()
      );

      const snapshots = await Promise.all(promises);

      snapshots.forEach((snapshot) => {
        snapshot.docs.forEach((doc) => {
          const token = doc.data().fcmToken;
          if (token) {
            targetTokens.push(token);
          }
        });
      });
    } else if (targetCities && targetCities.length > 0) {
      // Send to users in specific cities
      const citiesLower = targetCities.map((city: string) => city.toLowerCase());
      // Chunk cities to groups of 10 for 'in' query
      const chunks = chunkArray(citiesLower, 10);
      const promises = chunks.map((chunk) =>
        admin.firestore()
          .collection("users")
          .where("city", "in", chunk)
          .get()
      );

      const snapshots = await Promise.all(promises);

      snapshots.forEach((snapshot) => {
        snapshot.docs.forEach((doc) => {
          const token = doc.data().fcmToken;
          if (token) {
            targetTokens.push(token);
          }
        });
      });
    } else {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Must specify targetAll, targetUserIds, or targetCities."
      );
    }

    // Remove duplicates
    targetTokens = [...new Set(targetTokens)];

    if (targetTokens.length === 0) {
      throw new functions.https.HttpsError(
        "not-found",
        "No users found with FCM tokens for the specified criteria."
      );
    }

    // Send multicast message
    // FCM multicast also has limits (500 tokens), but sendEachForMulticast handles it internally?
    // Actually sendEachForMulticast takes an array of tokens and sends individually but in batches?
    // Wait, sendEachForMulticast: "Sends the given message to each of the specified recipients."
    // The documentation says: "The tokens parameter... can contain up to 500 tokens."
    // If we have more than 500 tokens, we should probably batch this too.

    // Let's implement batching for sending as well (chunk of 500)
    const tokenChunks = chunkArray(targetTokens, 500);
    let successCount = 0;
    let failureCount = 0;

    for (const chunk of tokenChunks) {
      const message = {
        notification: {
          title: title,
          body: body,
          ...(imageUrl && {imageUrl}),
        },
        data: customData || {},
        tokens: chunk,
      };

      const response = await admin.messaging().sendEachForMulticast(message);
      successCount += response.successCount;
      failureCount += response.failureCount;

      if (response.failureCount > 0) {
        console.log(`Failed to send ${response.failureCount} messages in this batch`);
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            console.error(`Error sending to token ${chunk[idx]}:`, resp.error);
          }
        });
      }
    }

    console.log(`Total: Successfully sent ${successCount} messages, failed ${failureCount}`);

    // Log the broadcast
    await admin.firestore().collection("broadcast_logs").add({
      title,
      body,
      targetType: targetUserIds.length > 0 ? "users" : "cities",
      targetIds: targetUserIds.length > 0 ? targetUserIds : targetCities,
      sentBy: context.auth.uid,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      successCount: successCount,
      failureCount: failureCount,
    });

    return {
      success: true,
      successCount: successCount,
      failureCount: failureCount,
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

/**
 * Helper function to chunk an array into smaller arrays
 * @template T
 * @param {Array<T>} array The array to chunk
 * @param {number} size The size of each chunk
 * @return {Array<Array<T>>} The chunked array
 */
function chunkArray<T>(array: T[], size: number): T[][] {
  const chunked: T[][] = [];
  for (let i = 0; i < array.length; i += size) {
    chunked.push(array.slice(i, i + size));
  }
  return chunked;
}
