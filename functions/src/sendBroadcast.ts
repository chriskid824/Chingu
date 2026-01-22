import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Ensure admin is initialized
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

  // Check admin permissions
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
    // Case 1: Send to all users via topic
    if (targetAll) {
      const message: admin.messaging.Message = {
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

      await logBroadcast({
        title,
        body,
        targetType: "all",
        sentBy: context.auth.uid,
        messageId: response,
      });

      return {success: true, messageId: response, recipients: "all"};
    }

    let targetTokens: string[] = [];

    // Case 2: Send to specific users
    if (targetUserIds && targetUserIds.length > 0) {
      // Chunk user IDs to respect Firestore 'in' limit of 10
      const chunks = chunkArray(targetUserIds, 10);

      for (const chunk of chunks) {
        const usersSnapshot = await admin.firestore()
          .collection("users")
          .where(admin.firestore.FieldPath.documentId(), "in", chunk)
          .get();

        const tokens = usersSnapshot.docs
          .map((doc) => doc.data().fcmToken)
          .filter((token) => token); // Filter out null/undefined

        targetTokens.push(...tokens);
      }
    }
    // Case 3: Send to specific cities
    else if (targetCities && targetCities.length > 0) {
      const citiesLower = targetCities.map((city: string) => city.toLowerCase());
      // Chunk cities to respect Firestore 'in' limit of 10
      const chunks = chunkArray(citiesLower, 10);

      for (const chunk of chunks) {
        const usersSnapshot = await admin.firestore()
          .collection("users")
          .where("city", "in", chunk)
          .get();

        const tokens = usersSnapshot.docs
          .map((doc) => doc.data().fcmToken)
          .filter((token) => token);

        targetTokens.push(...tokens);
      }
    } else {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Must specify targetAll, targetUserIds, or targetCities."
      );
    }

    // Remove duplicates if any
    targetTokens = [...new Set(targetTokens)];

    if (targetTokens.length === 0) {
      console.log("No valid FCM tokens found for the specified targets.");
      return {
        success: true,
        successCount: 0,
        failureCount: 0,
        message: "No users found with FCM tokens.",
      };
    }

    // Batch tokens for multicast (max 500 per batch)
    const tokenBatches = chunkArray(targetTokens, 500);
    let totalSuccess = 0;
    let totalFailure = 0;

    for (const batch of tokenBatches) {
      const message: admin.messaging.MulticastMessage = {
        notification: {
          title: title,
          body: body,
          ...(imageUrl && {imageUrl}),
        },
        data: customData || {},
        tokens: batch,
      };

      const response = await admin.messaging().sendEachForMulticast(message);
      totalSuccess += response.successCount;
      totalFailure += response.failureCount;

      if (response.failureCount > 0) {
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            console.error(`Error sending to token ${batch[idx]}:`, resp.error);
            // Optional: Handle invalid tokens (e.g. remove from DB)
          }
        });
      }
    }

    await logBroadcast({
      title,
      body,
      targetType: targetUserIds.length > 0 ? "users" : "cities",
      targetIds: targetUserIds.length > 0 ? targetUserIds : targetCities,
      sentBy: context.auth.uid,
      successCount: totalSuccess,
      failureCount: totalFailure,
    });

    return {
      success: true,
      successCount: totalSuccess,
      failureCount: totalFailure,
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

// Helper function to chunk arrays
function chunkArray<T>(array: T[], size: number): T[][] {
  const result = [];
  for (let i = 0; i < array.length; i += size) {
    result.push(array.slice(i, i + size));
  }
  return result;
}

// Helper function to log broadcast
async function logBroadcast(data: any) {
  try {
    await admin.firestore().collection("broadcast_logs").add({
      ...data,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (e) {
    console.error("Failed to log broadcast:", e);
  }
}
