import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {eventReminderTest, getNotificationCopy} from "./notification_content";

// Prevent duplicate initialization
if (admin.apps.length === 0) {
  admin.initializeApp();
}

/**
 * Scheduled function to send event reminders
 * Runs every hour
 */
export const sendEventReminders = functions.pubsub.schedule("every 1 hours").onRun(async () => {
  const db = admin.firestore();
  const now = new Date();

  // Calculate time windows
  // We look for events happening in roughly 24 hours and 2 hours
  // Using a 1-hour window centered around the target time to ensure we catch everything
  // even if the function execution is slightly delayed or drifted.

  // 24 Hour Reminder Window: [Now + 23h, Now + 25h]
  // Widen the window to 2 hours to handle execution delays/drifts
  const start24h = new Date(now.getTime() + (23 * 60 * 60 * 1000));
  const end24h = new Date(now.getTime() + (25 * 60 * 60 * 1000));

  // 2 Hour Reminder Window: [Now + 1h, Now + 3h]
  const start2h = new Date(now.getTime() + (1 * 60 * 60 * 1000));
  const end2h = new Date(now.getTime() + (3 * 60 * 60 * 1000));

  try {
    await Promise.all([
      processReminders(db, start24h, end24h, "24h"),
      processReminders(db, start2h, end2h, "2h"),
    ]);

    console.log("Successfully processed event reminders");
  } catch (error) {
    console.error("Error processing event reminders:", error);
  }
});

/**
 * Processes reminders for a given time window and type.
 * @param {admin.firestore.Firestore} db The Firestore instance.
 * @param {Date} start The start of the time window.
 * @param {Date} end The end of the time window.
 * @param {string} type The type of reminder ('24h' or '2h').
 * @return {Promise<void>} A promise that resolves when processing is complete.
 */
async function processReminders(
  db: admin.firestore.Firestore,
  start: Date,
  end: Date,
  type: "24h" | "2h"
) {
  const reminderField = type === "24h" ? "is24hReminderSent" : "is2hReminderSent";
  const timeLeftText = type === "24h" ? "24小時" : "2小時";

  // Query events in the time window
  const snapshot = await db.collection("dinner_events")
    .where("dateTime", ">=", start)
    .where("dateTime", "<=", end)
    .get();

  const updates: Promise<unknown>[] = [];

  for (const doc of snapshot.docs) {
    const event = doc.data();

    // Filter out cancelled events and already sent reminders
    if (event.status === "cancelled") continue;
    if (event[reminderField] === true) continue;

    const participantIds = event.participantIds as string[];
    if (!participantIds || participantIds.length === 0) continue;

    // Fetch user tokens
    // We do this individually or in batches. Since max participants is 6, checking individually or 'in' query is fine.
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

    if (tokens.length > 0) {
      // Prepare notification content
      const eventTime = (event.dateTime as admin.firestore.Timestamp).toDate();
      const timeString = eventTime.toLocaleString("zh-TW", {
        hour: "2-digit",
        minute: "2-digit",
        hour12: false,
        timeZone: "Asia/Taipei",
      });

      // Use 'countdown' variant for reminders
      const {title, body} = getNotificationCopy(
        eventReminderTest.testId,
        "countdown",
        {
          eventName: `${event.city} ${event.district} 晚餐`,
          timeLeft: timeLeftText,
          time: timeString,
        }
      );

      const message: admin.messaging.MulticastMessage = {
        notification: {
          title,
          body,
        },
        tokens: tokens,
        data: {
          type: "event_reminder",
          eventId: doc.id,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
      };

      // Send notification
      const sendPromise = admin.messaging().sendEachForMulticast(message)
        .then((response) => {
          console.log(`Sent ${type} reminders for event ${doc.id}: ` +
            `${response.successCount} success, ${response.failureCount} failure`);
        })
        .catch((error) => {
          console.error(`Error sending ${type} reminders for event ${doc.id}:`, error);
        });

      updates.push(sendPromise);
    }

    // Update event document to mark reminder as sent
    updates.push(doc.ref.update({
      [reminderField]: true,
    }));
  }

  await Promise.all(updates);
}
