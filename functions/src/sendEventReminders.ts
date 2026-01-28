import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Ensure admin is initialized
if (admin.apps.length === 0) {
  admin.initializeApp();
}

/**
 * Scheduled function to send dinner event reminders 24 hours in advance.
 * Runs every 60 minutes.
 */
export const sendEventReminders = functions.pubsub.schedule("every 60 minutes").onRun(async () => {
  const now = new Date();
  // Calculate the time window (24 hours from now, covering the next hour)
  // Example: If now is 10:00, we check for events between 10:00 tomorrow and 11:00 tomorrow.
  const startTime = new Date(now.getTime() + 24 * 60 * 60 * 1000);
  const endTime = new Date(startTime.getTime() + 60 * 60 * 1000);

  console.log(`Checking for events between ${startTime.toISOString()} and ${endTime.toISOString()}`);

  try {
    const eventsSnapshot = await admin.firestore()
      .collection("dinner_events")
      .where("dateTime", ">=", startTime)
      .where("dateTime", "<", endTime)
      .get();

    if (eventsSnapshot.empty) {
      console.log("No upcoming events found in this window.");
      return null;
    }

    let totalSent = 0;
    let totalEvents = 0;

    for (const doc of eventsSnapshot.docs) {
      const eventData = doc.data();
      const status = eventData.status;

      // Filter by status in memory to avoid composite index requirements
      if (status !== "confirmed" && status !== "pending") {
        console.log(`Skipping event ${doc.id} with status: ${status}`);
        continue;
      }

      totalEvents++;
      const participantIds: string[] = eventData.participantIds || [];

      if (participantIds.length === 0) {
        console.log(`Event ${doc.id} has no participants.`);
        continue;
      }

      // Fetch users to get FCM tokens and language preferences
      // Firestore 'in' query supports up to 10 items. If participants > 10 (max is 6 here), we are safe.
      // But if we increase max participants later, we should batch or loop.
      // Current max is 6.
      const usersSnapshot = await admin.firestore()
        .collection("users")
        .where(admin.firestore.FieldPath.documentId(), "in", participantIds)
        .get();

      const tokens: string[] = [];

      usersSnapshot.docs.forEach((userDoc) => {
        const userData = userDoc.data();
        if (userData.fcmToken) {
          tokens.push(userData.fcmToken);
        }
      });

      if (tokens.length === 0) {
        console.log(`No valid tokens found for event ${doc.id}`);
        continue;
      }

      // Construct the message
      // TODO: Localize based on user preference if possible. For now, use English/Default.
      // Or maybe Chinese since the codebase comments are Chinese.
      const eventTime = (eventData.dateTime as admin.firestore.Timestamp).toDate();
            const timeString = eventTime.toLocaleTimeString("zh-TW", {
                hour: "2-digit",
                minute: "2-digit",
                hour12: false,
            });

      const message: admin.messaging.MulticastMessage = {
        notification: {
          title: "晚餐活動提醒",
          body: `您的晚餐活動將在明天 ${timeString} 開始，別忘了準時出席喔！`,
        },
        data: {
          type: "event_reminder",
          eventId: doc.id,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        tokens: tokens,
      };

      const response = await admin.messaging().sendEachForMulticast(message);

      console.log(`Sent reminders for event ${doc.id}: ${response.successCount} success, ${response.failureCount} failed.`);
      totalSent += response.successCount;

      // Log to notification_logs
      await admin.firestore().collection("notification_logs").add({
        type: "event_reminder",
        eventId: doc.id,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        recipientCount: tokens.length,
        successCount: response.successCount,
        failureCount: response.failureCount,
      });
    }

    console.log(`Processed ${totalEvents} events, sent ${totalSent} notifications.`);
    return null;
  } catch (error) {
    console.error("Error sending event reminders:", error);
    return null;
  }
});
