import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

/**
 * Scheduled function to send reminders for dinner events.
 * Runs every hour and checks for events starting in 24 hours.
 */
export const sendEventReminders = functions.pubsub.schedule("every 1 hours").onRun(async (context) => {
  const now = new Date();

  // Align to the start of the current hour to avoid gaps/overlaps due to execution latency
  const anchor = new Date(now);
  anchor.setMinutes(0, 0, 0);

  // 24 hours from anchor
  const startWindow = new Date(anchor.getTime() + 24 * 60 * 60 * 1000);
  // 25 hours from anchor
  const endWindow = new Date(anchor.getTime() + 25 * 60 * 60 * 1000);

  console.log(`Checking for events between ${startWindow.toISOString()} and ${endWindow.toISOString()}`);

  try {
    const eventsSnapshot = await admin.firestore()
      .collection("dinner_events")
      .where("dateTime", ">=", startWindow)
      .where("dateTime", "<", endWindow)
      .get();

    if (eventsSnapshot.empty) {
      console.log("No events found for reminders.");
      return null;
    }

    const promises = eventsSnapshot.docs.map(async (doc) => {
      const event = doc.data();

      // Check for cancellation and if reminder was already sent
      if (event.status === "cancelled") {
        return;
      }
      if (event.reminderSent === true) {
          console.log(`Reminder already sent for event ${doc.id}`);
          return;
      }

      const participantIds: string[] = event.participantIds || [];
      if (participantIds.length === 0) {
        return;
      }

      // Fetch users to get FCM tokens
      const usersSnapshot = await admin.firestore()
        .collection("users")
        .where(admin.firestore.FieldPath.documentId(), "in", participantIds)
        .get();

      const tokens: string[] = [];
      usersSnapshot.forEach((userDoc) => {
        const userData = userDoc.data();
        if (userData.fcmToken) {
          tokens.push(userData.fcmToken);
        }
      });

      if (tokens.length === 0) {
        console.log(`No tokens found for event ${doc.id}`);
        // Mark as sent to avoid repeated checks (though time window usually prevents it)
        await doc.ref.update({ reminderSent: true });
        return;
      }

      const restaurantText = event.restaurantName ? event.restaurantName : "餐廳";

      // Send notification
      const message = {
        notification: {
          title: "明天有晚餐聚會！",
          body: `別忘了明天在 ${restaurantText} 的聚會喔！`,
        },
        tokens: tokens,
      };

      const response = await admin.messaging().sendEachForMulticast(message);
      console.log(`Sent reminders for event ${doc.id}: ${response.successCount} success, ${response.failureCount} failure`);

      // Mark as sent
      await doc.ref.update({ reminderSent: true });
    });

    await Promise.all(promises);
    return null;
  } catch (error) {
    console.error("Error sending event reminders:", error);
    return null;
  }
});
