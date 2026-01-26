import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {getNotificationCopy} from "./notification_content";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

/**
 * Scheduled function to send reminders for events starting in 24 hours.
 * Runs every hour.
 */
export const sendEventReminders = functions.pubsub.schedule("every 1 hours").onRun(async () => {
  const db = admin.firestore();
  const now = admin.firestore.Timestamp.now();

  // Calculate 24 hours from now
  // We want events starting between 24h and 25h from now (since we run every hour)
  const startRange = new Date(now.toDate().getTime() + 24 * 60 * 60 * 1000);
  const endRange = new Date(now.toDate().getTime() + 25 * 60 * 60 * 1000);

  const startTimestamp = admin.firestore.Timestamp.fromDate(startRange);
  const endTimestamp = admin.firestore.Timestamp.fromDate(endRange);

  try {
    const eventsSnapshot = await db.collection("dinner_events")
      .where("dateTime", ">=", startTimestamp)
      .where("dateTime", "<", endTimestamp)
      .get();

    // Filter out cancelled events in memory or add to query if index exists
    // Adding where("status", "!=", "cancelled") might require a composite index with range filter on dateTime.
    // To be safe and avoid index creation requirement errors during deployment, filter in memory.
    const events = eventsSnapshot.docs.filter((doc) => {
      const data = doc.data();
      return data.status !== "cancelled" && data.status !== "completed";
    });

    if (events.length === 0) {
      console.log("No events found starting in 24 hours.");
      return null;
    }

    console.log(`Found ${events.length} events starting in 24 hours.`);

    const promises = events.map(async (doc) => {
      const event = doc.data();
      const participantIds: string[] = event.participantIds || [];

      if (participantIds.length === 0) return;

      // Fetch tokens for participants
      // Firestore 'in' query supports up to 10 values. Max participants is 6.
      const usersSnapshot = await db.collection("users")
        .where(admin.firestore.FieldPath.documentId(), "in", participantIds)
        .get();

      const tokens: string[] = [];
      usersSnapshot.docs.forEach((userDoc) => {
        const userData = userDoc.data();
        if (userData.fcmToken) {
          tokens.push(userData.fcmToken);
        }
      });

      if (tokens.length === 0) return;

      // Get notification content
      // Using 'event_reminder_copy_v1' test ID and 'control' variant as default
      const eventName = event.district ? `${event.district} 晚餐` : "晚餐活動";
      // Format time: e.g., "19:00"
      const eventDate = (event.dateTime as admin.firestore.Timestamp).toDate();
      // Use a fixed time zone offset for Taiwan (UTC+8) or generic formatting
      // Since Cloud Functions run in UTC usually, adding 8 hours for Taiwan time display
      const taiwanTime = new Date(eventDate.getTime() + 8 * 60 * 60 * 1000);
      const timeString = taiwanTime.toISOString().substring(11, 16); // Extract HH:mm

      const content = getNotificationCopy(
        "event_reminder_copy_v1",
        "control",
        {
          eventName: eventName,
          time: timeString,
          timeLeft: "24 小時",
        }
      );

      const message = {
        notification: {
          title: content.title,
          body: content.body,
        },
        data: {
          type: "event_reminder",
          eventId: doc.id,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        tokens: tokens,
      };

      const response = await admin.messaging().sendEachForMulticast(message);
      console.log(
        `Sent reminders for event ${doc.id}: ${response.successCount} success, ${response.failureCount} failure`
      );
    });

    await Promise.all(promises);
    return null;
  } catch (error) {
    console.error("Error sending event reminders:", error);
    return null;
  }
});
