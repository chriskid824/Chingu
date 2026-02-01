import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

/**
 * Scheduled function to send reminders for dinner events happening in 24 hours.
 * Runs every hour.
 */
export const sendEventReminders = functions.pubsub
  .schedule("every 1 hours")
  .onRun(async (context) => {
    const db = admin.firestore();
    const now = new Date();

    // Look for events ~24 hours from now.
    // We check a window of [now + 23.5h, now + 24.5h] to ensure we catch events
    // even if the scheduler is slightly off or if event times are not exactly on the hour.
    // By checking 'is24hReminderSent == false', we avoid duplicate reminders.
    const startWindow = new Date(now.getTime() + (23.5 * 60 * 60 * 1000));
    const endWindow = new Date(now.getTime() + (24.5 * 60 * 60 * 1000));

    console.log(`Checking for events between ${startWindow.toISOString()} and ${endWindow.toISOString()}`);

    try {
      const snapshot = await db.collection("dinner_events")
        .where("dateTime", ">=", startWindow)
        .where("dateTime", "<=", endWindow)
        .where("is24hReminderSent", "==", false)
        .get();

      if (snapshot.empty) {
        console.log("No upcoming events found for reminders.");
        return null;
      }

      console.log(`Found ${snapshot.size} events to remind.`);

      const promises = snapshot.docs.map(async (doc) => {
        const eventData = doc.data();
        const participantIds: string[] = eventData.participantIds || [];

        if (participantIds.length === 0) {
            // Mark as sent even if no participants, to stop checking this event
            await doc.ref.update({ is24hReminderSent: true });
            return;
        }

        // Fetch users to get tokens
        // Since max participants is 6, 'in' query works fine (limit is 30 in some SDKs, 10 in older).
        // Firestore 'in' supports up to 10 values. If we increase max participants later, we need to batch.

        // For safety, let's slice chunks of 10 if needed, but for now 6 is fine.
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
            const message = {
                notification: {
                    title: "Dinner Reminder",
                    body: "Your dinner event is tomorrow! Don't forget to check the details.",
                },
                tokens: tokens,
            };

            const response = await admin.messaging().sendEachForMulticast(message);
            console.log(`Sent reminders for event ${doc.id}: ${response.successCount} success, ${response.failureCount} failed.`);

            if (response.failureCount > 0) {
                response.responses.forEach((resp, idx) => {
                    if (!resp.success) {
                        console.error(`Error sending to token ${tokens[idx]}:`, resp.error);
                        // Optional: remove invalid tokens from user doc
                    }
                });
            }
        } else {
            console.log(`Event ${doc.id} has participants but no valid FCM tokens.`);
        }

        // Mark as sent
        await doc.ref.update({ is24hReminderSent: true });
      });

      await Promise.all(promises);
      console.log("Finished sending reminders.");
      return null;

    } catch (error) {
      console.error("Error sending event reminders:", error);
      return null;
    }
  });
