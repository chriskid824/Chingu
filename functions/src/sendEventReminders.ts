import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

/**
 * Scheduled function to send event reminders.
 * Runs every 30 minutes.
 * Sends reminders 24 hours and 2 hours before the event.
 */
export const sendEventReminders = functions.pubsub
  .schedule("every 30 minutes")
  .onRun(async (context) => {
    const db = admin.firestore();
    const now = new Date();

    // Calculate time windows
    // 24h reminder: Check events starting between 23h and 25h from now
    const start24h = new Date(now.getTime() + 23 * 60 * 60 * 1000);
    const end24h = new Date(now.getTime() + 25 * 60 * 60 * 1000);

    // 2h reminder: Check events starting between 1.5h and 2.5h from now
    const start2h = new Date(now.getTime() + 1.5 * 60 * 60 * 1000);
    const end2h = new Date(now.getTime() + 2.5 * 60 * 60 * 1000);

    // We can't easily query multiple ranges in one go efficiently without multiple queries.
    // Let's run two queries.

    try {
      // 1. Process 24h reminders
      const events24h = await db.collection("dinner_events")
        .where("status", "==", "confirmed")
        .where("dateTime", ">=", start24h)
        .where("dateTime", "<=", end24h)
        .where("reminder24hSent", "==", false)
        .get();

      // 2. Process 2h reminders
      const events2h = await db.collection("dinner_events")
        .where("status", "==", "confirmed")
        .where("dateTime", ">=", start2h)
        .where("dateTime", "<=", end2h)
        .where("reminder2hSent", "==", false)
        .get();

      const batch = db.batch();
      let operationCount = 0;

      // Function to send notifications
      const sendReminders = async (docs: FirebaseFirestore.QueryDocumentSnapshot[], type: "24h" | "2h") => {
        for (const doc of docs) {
          const eventData = doc.data();
          const participantIds = eventData.participantIds as string[];
          const dateTime = (eventData.dateTime as admin.firestore.Timestamp).toDate();

          // Format time for display (Asia/Taipei)
          // Using basic formatting since we might not have timezone libs
          // ISO string is UTC.
          // Taipei is UTC+8.
          const taipeiTime = new Date(dateTime.getTime() + 8 * 60 * 60 * 1000);
          const timeString = taipeiTime.toISOString().replace("T", " ").substring(0, 16); // YYYY-MM-DD HH:mm

          if (participantIds && participantIds.length > 0) {
            // Get user tokens
            const usersSnapshot = await db.collection("users")
              .where(admin.firestore.FieldPath.documentId(), "in", participantIds)
              .get();

            const tokens: string[] = [];
            usersSnapshot.docs.forEach(userDoc => {
              const userData = userDoc.data();
              if (userData.fcmToken) {
                tokens.push(userData.fcmToken);
              }
            });

            if (tokens.length > 0) {
              const title = type === "24h"
                ? "活動提醒：明天有晚餐活動！"
                : "活動提醒：晚餐活動即將開始！";

              const body = type === "24h"
                ? `您的晚餐活動將於明天 ${timeString} 開始，請準時出席。`
                : `您的晚餐活動將於 ${timeString} 開始，別遲到囉！`;

              // Send multicast message
              const message = {
                notification: {
                  title: title,
                  body: body,
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
                console.log(`Sent ${type} reminders for event ${doc.id}: ${response.successCount} success, ${response.failureCount} failed.`);
              } catch (e) {
                console.error(`Error sending FCM for event ${doc.id}:`, e);
              }
            }
          }

          // Update event document
          const updateData = type === "24h"
            ? { reminder24hSent: true }
            : { reminder2hSent: true };

          batch.update(doc.ref, updateData);
          operationCount++;
        }
      };

      await sendReminders(events24h.docs, "24h");
      await sendReminders(events2h.docs, "2h");

      if (operationCount > 0) {
        await batch.commit();
        console.log(`Committed ${operationCount} updates.`);
      }

    } catch (error) {
      console.error("Error in sendEventReminders:", error);
    }
  });
