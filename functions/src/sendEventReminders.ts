import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {getUserNotificationCopy, eventReminderTest} from "./notification_content";

// Define a simplified interface for DinnerEvent based on the Dart model
interface DinnerEvent {
    id: string; // Document ID
    dateTime: admin.firestore.Timestamp;
    city: string;
    restaurantName?: string;
    participantIds: string[];
    participantStatus: { [uid: string]: string };
    reminder24hSent?: boolean;
    reminder2hSent?: boolean;
    status: string;
}

/**
 * Scheduled function to send event reminders
 * Runs every 60 minutes
 */
export const sendEventReminders = functions.pubsub.schedule("every 60 minutes").onRun(async () => {
  if (admin.apps.length === 0) {
    admin.initializeApp();
  }
  const db = admin.firestore();
  const now = new Date();

  console.log("Starting event reminder check at:", now.toISOString());

  // 24 Hour Reminders
  // Window: [now + 23h, now + 25h]
  // This allows for some flexibility in execution time
  const start24h = new Date(now.getTime() + 23 * 60 * 60 * 1000);
  const end24h = new Date(now.getTime() + 25 * 60 * 60 * 1000);

  await processReminders(db, start24h, end24h, "24h");

  // 2 Hour Reminders
  // Window: [now + 1h, now + 3h]
  const start2h = new Date(now.getTime() + 1 * 60 * 60 * 1000);
  const end2h = new Date(now.getTime() + 3 * 60 * 60 * 1000);

  await processReminders(db, start2h, end2h, "2h");

  console.log("Finished event reminder check");
  return null;
});

/**
 * Process event reminders for a specific time window
 * @param {admin.firestore.Firestore} db Firestore instance
 * @param {Date} start Window start time
 * @param {Date} end Window end time
 * @param {"24h" | "2h"} type Reminder type
 */
async function processReminders(
  db: admin.firestore.Firestore,
  start: Date,
  end: Date,
  type: "24h" | "2h"
) {
  const reminderField: keyof DinnerEvent = type === "24h" ? "reminder24hSent" : "reminder2hSent";
  const timeLeftText = type === "24h" ? "24小時" : "2小時"; // Using Chinese as app seems to use it

  try {
    const eventsSnapshot = await db.collection("dinner_events")
      .where("dateTime", ">=", start)
      .where("dateTime", "<=", end)
      .where("status", "in", ["confirmed", "pending"]) // Only active events
      .get();

    const eventsToProcess = eventsSnapshot.docs.filter((doc) => {
      const data = doc.data() as DinnerEvent;
      // Filter if reminder already sent
      // We check for true explicitly. If undefined/false, we proceed.
      return data[reminderField] !== true;
    });

    console.log(`Found ${eventsToProcess.length} events for ${type} reminders.`);

    for (const doc of eventsToProcess) {
      const event = doc.data() as DinnerEvent;
      // Double check status just in case
      if (event.status === "cancelled" || event.status === "completed") continue;

      const confirmedParticipants = Object.entries(event.participantStatus)
        .filter(([, status]) => status === "confirmed")
        .map(([uid]) => uid);

      if (confirmedParticipants.length === 0) {
        console.log(`No confirmed participants for event ${doc.id}`);
        continue;
      }

      // Get tokens
      const usersSnapshot = await db.collection("users")
        .where(admin.firestore.FieldPath.documentId(), "in", confirmedParticipants)
        .get();

      // Format time for display (Asia/Taipei)
      const eventTime = event.dateTime.toDate();
      // Create a formatter for Taipei time
      const timeFormatter = new Intl.DateTimeFormat("zh-TW", {
        timeZone: "Asia/Taipei",
        month: "numeric",
        day: "numeric",
        hour: "2-digit",
        minute: "2-digit",
        hour12: false,
      });
      const timeString = timeFormatter.format(eventTime);

      const eventName = event.restaurantName ? `晚餐聚會 @ ${event.restaurantName}` : "晚餐聚會";

      // Prepare notifications
      const sendPromises = usersSnapshot.docs.map(async (userDoc) => {
        const userData = userDoc.data();
        const fcmToken = userData.fcmToken;

        if (!fcmToken) return;

        const {title, body} = await getUserNotificationCopy(
          db,
          userDoc.id,
          eventReminderTest.testId,
          {
            eventName: eventName,
            time: timeString,
            timeLeft: timeLeftText,
          }
        );

        const message = {
          notification: {
            title,
            body,
          },
          data: {
            type: "event_reminder",
            eventId: doc.id,
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          },
          token: fcmToken,
        };

        try {
          await admin.messaging().send(message);
        } catch (e) {
          console.error(`Failed to send reminder to user ${userDoc.id}`, e);
        }
      });

      await Promise.all(sendPromises);

      // Update event document
      await doc.ref.update({
        [reminderField]: true,
      });

      console.log(`Sent ${type} reminders for event ${doc.id}`);
    }
  } catch (error) {
    console.error(`Error processing ${type} reminders:`, error);
  }
}
