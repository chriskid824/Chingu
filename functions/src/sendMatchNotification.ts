import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {getNotificationCopy} from "./notification_content";

// Ensure Firebase Admin is initialized
if (admin.apps.length === 0) {
  admin.initializeApp();
}

/**
 * Sends push notifications to both users upon a successful match.
 *
 * Expected data:
 * - targetUserId: string
 */
export const sendMatchNotification = functions.https.onCall(async (data, context) => {
  // 1. Authentication check
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  const {targetUserId} = data;
  const currentUserId = context.auth.uid;

  // 2. Validation
  if (!targetUserId || typeof targetUserId !== "string") {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "The function must be called with a valid 'targetUserId'."
    );
  }

  try {
    // 3. Fetch user documents
    const [currentUserDoc, targetUserDoc] = await Promise.all([
      admin.firestore().collection("users").doc(currentUserId).get(),
      admin.firestore().collection("users").doc(targetUserId).get(),
    ]);

    if (!currentUserDoc.exists || !targetUserDoc.exists) {
      throw new functions.https.HttpsError(
        "not-found",
        "One or both users not found."
      );
    }

    const currentUser = currentUserDoc.data();
    const targetUser = targetUserDoc.data();

    // 4. Prepare notifications
    const messages: admin.messaging.Message[] = [];

    // Notify Current User (optional, but good for consistency)
    if (currentUser?.fcmToken) {
      const copy = getNotificationCopy("match_success_copy_v1", "control", {
        userName: targetUser?.name || "Someone",
      });

      messages.push({
        token: currentUser.fcmToken,
        notification: {
          title: copy.title,
          body: copy.body,
        },
        data: {
          actionType: "match_history",
          targetUserId: targetUserId,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
      });
    }

    // Notify Target User
    if (targetUser?.fcmToken) {
      const copy = getNotificationCopy("match_success_copy_v1", "control", {
        userName: currentUser?.name || "Someone",
      });

      messages.push({
        token: targetUser.fcmToken,
        notification: {
          title: copy.title,
          body: copy.body,
        },
        data: {
          actionType: "match_history",
          targetUserId: currentUserId,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
      });
    }

    // 5. Send messages
    if (messages.length > 0) {
      await Promise.all(messages.map((msg) => admin.messaging().send(msg)));
      console.log(`Sent match notifications to ${messages.length} users.`);
    }

    return {
      success: true,
      sentCount: messages.length,
    };
  } catch (error) {
    console.error("Error sending match notification:", error);
    throw new functions.https.HttpsError(
      "internal",
      "Failed to send match notifications.",
      error
    );
  }
});
