import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

export const sendMatchNotification = functions.https.onCall(async (data, context) => {
  // Check auth
  if (!context.auth) {
      throw new functions.https.HttpsError(
          "unauthenticated",
          "Only authenticated users can send match notifications."
      );
  }

  const { user1Id, user2Id } = data;

  if (!user1Id || !user2Id) {
      throw new functions.https.HttpsError(
          "invalid-argument",
          "Both user1Id and user2Id are required."
      );
  }

  const db = admin.firestore();

  try {
      // Security Check: Verify mutual match exists
      const swipesCollection = db.collection("swipes");

      const [swipe1, swipe2] = await Promise.all([
          swipesCollection
              .where("userId", "==", user1Id)
              .where("targetUserId", "==", user2Id)
              .where("isLike", "==", true)
              .limit(1)
              .get(),
          swipesCollection
              .where("userId", "==", user2Id)
              .where("targetUserId", "==", user1Id)
              .where("isLike", "==", true)
              .limit(1)
              .get()
      ]);

      if (swipe1.empty || swipe2.empty) {
          console.error(`Match verification failed for ${user1Id} and ${user2Id}`);
           throw new functions.https.HttpsError(
              "permission-denied",
              "Match verification failed. Users have not matched."
          );
      }

      // Fetch users
      const user1Doc = await db.collection("users").doc(user1Id).get();
      const user2Doc = await db.collection("users").doc(user2Id).get();

      if (!user1Doc.exists || !user2Doc.exists) {
          console.error("One or both users not found");
          return { success: false, error: "Users not found" };
      }

      const user1Data = user1Doc.data();
      const user2Data = user2Doc.data();

      const promises = [];

      // Send to User 1
      if (user1Data?.fcmToken) {
          const message1 = {
              notification: {
                  title: "It's a Match! 🎉",
                  body: `You matched with ${user2Data?.name || "someone"}!`,
              },
              data: {
                  type: "match",
                  partnerId: user2Id,
              },
              token: user1Data.fcmToken,
          };
          promises.push(admin.messaging().send(message1));
      }

      // Send to User 2
      if (user2Data?.fcmToken) {
          const message2 = {
              notification: {
                  title: "It's a Match! 🎉",
                  body: `You matched with ${user1Data?.name || "someone"}!`,
              },
              data: {
                  type: "match",
                  partnerId: user1Id,
              },
              token: user2Data.fcmToken,
          };
          promises.push(admin.messaging().send(message2));
      }

      const results = await Promise.allSettled(promises);

      let successCount = 0;
      results.forEach((result) => {
        if (result.status === 'fulfilled') {
            successCount++;
        } else {
            console.error("Failed to send notification:", result.reason);
        }
      });

      return { success: true, count: successCount, total: promises.length };

  } catch (error) {
      // Re-throw HttpsError as is
      if (error instanceof functions.https.HttpsError) {
          throw error;
      }
      console.error("Error sending match notifications:", error);
       throw new functions.https.HttpsError(
          "internal",
          "Failed to send match notifications.",
          error
      );
  }
});
