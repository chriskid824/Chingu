import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {eventReminderTest, getNotificationCopy} from "./notification_content";

// Initialize admin if not already initialized
if (admin.apps.length === 0) {
  admin.initializeApp();
}

/**
 * Scheduled function to send event reminders
 * Runs every hour to check for upcoming events
 * Sends reminders:
 * 1. 24 hours before event (start time between 23h and 25h from now)
 * 2. 2 hours before event (start time between 1h and 3h from now)
 *
 * Uses 'reminderSent24h' and 'reminderSent2h' flags to ensure idempotency.
 */
export const sendEventReminders = functions.pubsub
  .schedule("every 1 hours")
  .timeZone("Asia/Taipei")
  .onRun(async () => {
    const now = admin.firestore.Timestamp.now();
    const nowMillis = now.toMillis();

    // Time ranges
    const oneHourMillis = 60 * 60 * 1000;

    // 24 hours from now (range: 23h to 25h to handle scheduler drift)
    // We look for events that start roughly 24 hours from now.
    // Widening the window to ensure we catch everything, relying on flags to prevent duplicates.
    const start24h = new Date(nowMillis + 23 * oneHourMillis);
    const end24h = new Date(nowMillis + 25 * oneHourMillis);

    // 2 hours from now (range: 1.5h to 3h)
    const start2h = new Date(nowMillis + 1.5 * oneHourMillis);
    const end2h = new Date(nowMillis + 3 * oneHourMillis);

    const db = admin.firestore();
    const eventsRef = db.collection("dinner_events");

    console.log(`Checking for reminders at ${now.toDate().toISOString()}`);

    try {
      // 1. Process 24h reminders
      const events24h = await eventsRef
        .where("status", "==", "confirmed")
        .where("dateTime", ">=", start24h)
        .where("dateTime", "<", end24h)
        .get();

      // 2. Process 2h reminders
      const events2h = await eventsRef
        .where("status", "==", "confirmed")
        .where("dateTime", ">=", start2h)
        .where("dateTime", "<", end2h)
        .get();

      // Function to process events
      const processEvents = async (snapshot: admin.firestore.QuerySnapshot, type: "24h" | "2h") => {
        const batch = db.batch();
        let commitNeeded = false;

        for (const doc of snapshot.docs) {
          const event = doc.data();

          // Skip if reminder already sent
          if (type === "24h" && event.reminderSent24h) {
            continue;
          }
          if (type === "2h" && event.reminderSent2h) {
            continue;
          }

          const participantIds: string[] = event.participantIds || [];
          if (participantIds.length === 0) continue;

          // Fetch user tokens
          const usersSnapshot = await db.collection("users")
            .where(admin.firestore.FieldPath.documentId(), "in", participantIds)
            .get();

          const tokens: string[] = [];
          usersSnapshot.forEach((userDoc) => {
            const userData = userDoc.data();
            if (userData.fcmToken) {
              tokens.push(userData.fcmToken);
            }
          });

          if (tokens.length > 0) {
            const eventDate = (event.dateTime as admin.firestore.Timestamp).toDate();
            const timeString = eventDate.toLocaleTimeString("zh-TW", {
              hour: "2-digit",
              minute: "2-digit",
              hour12: false,
              timeZone: "Asia/Taipei",
            });

            const restaurant = event.restaurantName || "指定餐廳";

            // Use A/B testing content
            // For now we use the default variant 'control' as we don't have user-specific variant assignment
            // in this batch context easily.
            // Or we could try to assign variants, but 'getNotificationCopy' takes a variantId.
            // We will use 'control' for simplicity and consistency in this version.
            const params = {
              eventName: "聚餐活動",
              time: timeString,
              timeLeft: type === "24h" ? "1天" : "2小時",
              restaurant: restaurant,
            };

            // Override content for specific types to match the desired message in the task roughly
            // The existing eventReminderTest has:
            // control: "{eventName} 將於 {time} 開始"
            // countdown: "{eventName} 還有 {timeLeft} 就要開始了"
            // motivating: "{eventName} 即將開始，期待與你見面!"

            // We can select a variant based on type.
            // For 24h: "control" is good.
            // For 2h: "countdown" is good.

            const variantId = type === "24h" ? "control" : "countdown";
            const content = getNotificationCopy(
              eventReminderTest.testId,
              variantId,
              params
            );

            // Customizing body slightly if needed or relying on the template.
            // The template uses {eventName}, {time}, {timeLeft}.
            // Let's ensure params match what getNotificationCopy expects in templates.

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

            try {
              const response = await admin.messaging().sendEachForMulticast(message);
              console.log(
                `Sent ${type} reminders for event ${doc.id}: ` +
                                `${response.successCount} success, ${response.failureCount} failure`
              );

              // Only mark as sent if we successfully processed it (at least attempted)
              batch.update(doc.ref, {
                [type === "24h" ? "reminderSent24h" : "reminderSent2h"]: true,
              });
              commitNeeded = true;
            } catch (e) {
              console.error(`Error sending ${type} reminders for event ${doc.id}:`, e);
            }
          } else {
            // No tokens, but we should still mark as sent so we don't keep retrying forever if users have no tokens
            batch.update(doc.ref, {
              [type === "24h" ? "reminderSent24h" : "reminderSent2h"]: true,
            });
            commitNeeded = true;
          }
        }

        if (commitNeeded) {
          await batch.commit();
          console.log(`Updated flags for ${type} reminders`);
        }
      };

      await Promise.all([
        processEvents(events24h, "24h"),
        processEvents(events2h, "2h"),
      ]);
    } catch (error) {
      console.error("Error in sendEventReminders:", error);
    }

    return null;
  });
