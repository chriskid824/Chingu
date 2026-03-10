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
      const chunks = [];
      for (let i = 0; i < targetUserIds.length; i += 30) {
        chunks.push(targetUserIds.slice(i, i + 30));
      }

      const snapshots = await Promise.all(chunks.map((chunk) =>
        admin.firestore()
          .collection("users")
          .where(admin.firestore.FieldPath.documentId(), "in", chunk)
          .select("fcmToken", "notificationSettings")
          .get()
      ));

      targetTokens = snapshots.flatMap((snap) => snap.docs)
        .filter((doc) => {
          const userData = doc.data();
          // Check if notificationSettings exists and pushEnabled is explicitly false
          if (userData.notificationSettings && userData.notificationSettings.pushEnabled === false) {
            return false;
          }
          return !!userData.fcmToken;
        })
        .map((doc) => doc.data().fcmToken);
    } else if (targetCities && targetCities.length > 0) {
      // Send to users in specific cities
      const chunks = [];
      for (let i = 0; i < targetCities.length; i += 30) {
        chunks.push(targetCities.slice(i, i + 30));
      }

      const snapshots = await Promise.all(chunks.map((chunk) =>
        admin.firestore()
          .collection("users")
          .where("city", "in", chunk)
          .select("fcmToken", "notificationSettings")
          .get()
      ));

      targetTokens = snapshots.flatMap((snap) => snap.docs)
        .filter((doc) => {
          const userData = doc.data();
          // Check if notificationSettings exists and pushEnabled is explicitly false
          if (userData.notificationSettings && userData.notificationSettings.pushEnabled === false) {
            return false;
          }
          return !!userData.fcmToken;
        })
        .map((doc) => doc.data().fcmToken);
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

    // Send multicast message in batches of 500 (FCM limit)
    let successCount = 0;
    let failureCount = 0;
    const tokenChunks = [];

    for (let i = 0; i < targetTokens.length; i += 500) {
      tokenChunks.push(targetTokens.slice(i, i + 500));
    }

    console.log(`Sending broadcast to ${targetTokens.length} tokens in ${tokenChunks.length} batches`);

    const responses = await Promise.all(tokenChunks.map(async (chunk) => {
      const message = {
        notification: {
          title: title,
          body: body,
          ...(imageUrl && {imageUrl}),
        },
        data: customData || {},
        tokens: chunk,
      };

      try {
        const response = await admin.messaging().sendEachForMulticast(message);
        return {
          successCount: response.successCount,
          failureCount: response.failureCount,
          responses: response.responses,
          tokens: chunk,
        };
      } catch (e) {
        console.error("Error sending batch:", e);
        return {
          successCount: 0,
          failureCount: chunk.length,
          responses: [],
          tokens: chunk,
          error: e,
        };
      }
    }));

    // Aggregate results
    responses.forEach((resp) => {
      successCount += resp.successCount;
      failureCount += resp.failureCount;

      if (resp.failureCount > 0 && resp.responses) {
        resp.responses.forEach((r, idx) => {
          if (!r.success) {
            console.error(`Error sending to token ${resp.tokens[idx]}:`, r.error);
          }
        });
      }
    });

    console.log(`Successfully sent ${successCount} messages, failed ${failureCount}`);

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
