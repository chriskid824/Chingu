import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

/**
 * Sends a push notification to both users when a match occurs.
 * Includes A/B testing logic for notification content.
 */
export const notifyMatch = functions.https.onCall(async (data, context) => {
  // Ensure the user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  const user1Id = data.user1Id;
  const user2Id = data.user2Id;

  if (!user1Id || !user2Id) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "The function must be called with user1Id and user2Id."
    );
  }

  // Ensure the caller is one of the matched users
  const callerId = context.auth.uid;
  if (callerId !== user1Id && callerId !== user2Id) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "You can only trigger notifications for your own matches."
    );
  }

  try {
    // Fetch both users in parallel
    const [user1Doc, user2Doc] = await Promise.all([
      admin.firestore().collection("users").doc(user1Id).get(),
      admin.firestore().collection("users").doc(user2Id).get(),
    ]);

    const user1 = user1Doc.data();
    const user2 = user2Doc.data();

    const notifications: Promise<string>[] = [];

    // Helper to determine A/B group (Control vs Variant)
    const isVariant = (userId: string) => {
      let hash = 0;
      for (let i = 0; i < userId.length; i++) {
        const char = userId.charCodeAt(i);
        hash = ((hash << 5) - hash) + char;
        hash = hash & hash;
      }
      return hash % 2 !== 0;
    };

    // Prepare notification for User 1
    if (user1?.fcmToken) {
      const variant = isVariant(user1Id);
      const partnerName = user2?.name || "Someone";

      const title = variant ? "New Match! 🎉" : "New Match";
      const body = variant
        ? `You matched with ${partnerName}! Say hi now! 👋`
        : `You have a new match with ${partnerName}.`;

      notifications.push(admin.messaging().send({
        token: user1.fcmToken,
        notification: {
          title: title,
          body: body,
        },
        data: {
          type: "match",
          actionType: "open_chat",
          partnerId: user2Id,
        },
      }));
    }

    // Prepare notification for User 2
    if (user2?.fcmToken) {
      const variant = isVariant(user2Id);
      const partnerName = user1?.name || "Someone";

      const title = variant ? "New Match! 🎉" : "New Match";
      const body = variant
        ? `You matched with ${partnerName}! Say hi now! 👋`
        : `You have a new match with ${partnerName}.`;

      notifications.push(admin.messaging().send({
        token: user2.fcmToken,
        notification: {
          title: title,
          body: body,
        },
        data: {
          type: "match",
          actionType: "open_chat",
          partnerId: user1Id,
        },
      }));
    }

    if (notifications.length > 0) {
      await Promise.all(notifications);
    }

    return { success: true, notificationsSent: notifications.length };

  } catch (error) {
    console.error("Error sending match notifications:", error);
    throw new functions.https.HttpsError("internal", "Unable to send notifications");
  }
});
