import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

/**
 * Sends a broadcast or targeted notification.
 * This function is restricted to admin users only.
 *
 * Accepted data payload:
 * - title: string (required)
 * - body: string (required)
 * - target: 'all' | string[] (optional, defaults to 'all'. List of user IDs for targeted)
 * - data: map (optional, custom data payload)
 * - imageUrl: string (optional)
 */
export const sendBroadcast = functions.https.onCall(async (data, context) => {
  // 1. Authentication & Authorization Check
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  const uid = context.auth.uid;

  // Check if user is admin via isAdmin field in Firestore.
  const userDoc = await admin.firestore().collection("users").doc(uid).get();
  const userData = userDoc.data();
  // Ensure strict admin check. Remove hardcoded emails for production readiness.
  const isAdmin = userData?.isAdmin === true;

  if (!isAdmin) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Only administrators can send broadcasts."
    );
  }

  // 2. Input Validation
  const { title, body, target, data: customData, imageUrl } = data;

  if (!title || !body) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "The function must be called with 'title' and 'body'."
    );
  }

  // 3. Prepare Notification Payload
  const messagePayload: admin.messaging.MulticastMessage = {
    notification: {
      title: title,
      body: body,
      imageUrl: imageUrl, // Optional image
    },
    data: {
      ...customData,
      click_action: "FLUTTER_NOTIFICATION_CLICK",
      type: "system_broadcast", // Default type
    },
    // We will set tokens later based on target
    tokens: [],
  };

  // Android specific config
  messagePayload.android = {
    notification: {
      channelId: "channel_system", // Use system channel
      priority: "high",
      defaultSound: true,
    }
  };

  // Apple specific config
  messagePayload.apns = {
    payload: {
      aps: {
        sound: "default",
        contentAvailable: true,
      }
    }
  };

  try {
    let tokens: string[] = [];

    // 4. Determine Target Audience
    if (!target || target === "all") {
        // Fetch all users with fcmTokens
        // WARNING: This operation reads all user documents and scales linearly (O(N)).
        // For production with large user base, consider using FCM Topics or paginated Cloud Tasks.
        const usersSnapshot = await admin.firestore().collection("users").get();
        usersSnapshot.docs.forEach(doc => {
            const uData = doc.data();
            if (uData.fcmTokens && Array.isArray(uData.fcmTokens)) {
                tokens.push(...uData.fcmTokens);
            } else if (uData.fcmToken) { // Fallback for single token
                tokens.push(uData.fcmToken);
            }
        });

    } else if (Array.isArray(target)) {
        // Targeted users
        // Firestore 'in' query is limited to 30 items.
        // We use getAll for direct ID lookups which is more efficient and flexible.
        const refs = target.map(id => admin.firestore().collection("users").doc(id));

        // getAll supports variable number of arguments, but for array input we spread it.
        // However, if the array is massive, we should still chunk it to avoid memory issues,
        // though getAll handles a lot. Let's chunk to be safe (e.g., 100 at a time).
        const chunkSize = 100;
        for (let i = 0; i < refs.length; i += chunkSize) {
            const chunkRefs = refs.slice(i, i + chunkSize);
            const snapshots = await admin.firestore().getAll(...chunkRefs);

            snapshots.forEach(doc => {
                if (doc.exists) {
                    const uData = doc.data();
                    if (uData && uData.fcmTokens && Array.isArray(uData.fcmTokens)) {
                        tokens.push(...uData.fcmTokens);
                    } else if (uData && uData.fcmToken) {
                        tokens.push(uData.fcmToken);
                    }
                }
            });
        }
    } else {
         throw new functions.https.HttpsError(
            "invalid-argument",
            "Target must be 'all' or an array of user IDs."
        );
    }

    // Dedup tokens
    tokens = [...new Set(tokens)];

    if (tokens.length === 0) {
        return { success: true, message: "No devices to send to." };
    }

    // 5. Send Notifications (Batched)
    // sendMulticast handles up to 500 tokens at a time.
    const batchSize = 500;
    const batchPromises = [];

    for (let i = 0; i < tokens.length; i += batchSize) {
        const batchTokens = tokens.slice(i, i + batchSize);
        const batchMessage = { ...messagePayload, tokens: batchTokens };
        batchPromises.push(admin.messaging().sendEachForMulticast(batchMessage as admin.messaging.MulticastMessage));
    }

    const responses = await Promise.all(batchPromises);

    let successCount = 0;
    let failureCount = 0;

    responses.forEach(response => {
        successCount += response.successCount;
        failureCount += response.failureCount;
    });

    // Optional: Log stats to Firestore 'notification_stats'
    const statsRef = admin.firestore().collection("notification_stats").doc(`broadcast_${Date.now()}`);
    await statsRef.set({
        type: 'broadcast',
        title: title,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        targetCount: tokens.length,
        successCount: successCount,
        failureCount: failureCount,
        senderId: uid
    });

    return {
        success: true,
        successCount,
        failureCount,
        message: `Broadcast sent to ${successCount} devices.`
    };

  } catch (error) {
    console.error("Error sending broadcast:", error);
    throw new functions.https.HttpsError("internal", "Failed to send broadcast", error);
  }
});
