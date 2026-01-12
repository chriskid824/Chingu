import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

/**
 * Scheduled function to send event reminders 24 hours and 2 hours before the event.
 * Runs every 15 minutes.
 */
export const sendEventReminders = onSchedule("every 15 minutes", async (event) => {
  const now = new Date();

  // 1. Process 24-hour reminders
  // Look for events starting between (24h - 5m) and (24h + 15m) from now
  // We add a 5 minute overlap to handle scheduler jitter
  const remind24hStart = new Date(now.getTime() + 24 * 60 * 60 * 1000 - 5 * 60 * 1000);
  const remind24hEnd = new Date(now.getTime() + 24 * 60 * 60 * 1000 + 15 * 60 * 1000);

  // 2. Process 2-hour reminders
  // Look for events starting between (2h - 5m) and (2h + 15m) from now
  const remind2hStart = new Date(now.getTime() + 2 * 60 * 60 * 1000 - 5 * 60 * 1000);
  const remind2hEnd = new Date(now.getTime() + 2 * 60 * 60 * 1000 + 15 * 60 * 1000);

  console.log(`Checking for events 24h reminder between ${remind24hStart.toISOString()} and ${remind24hEnd.toISOString()}`);
  console.log(`Checking for events 2h reminder between ${remind2hStart.toISOString()} and ${remind2hEnd.toISOString()}`);

  try {
    // We process them sequentially or use allSettled to isolate errors
    const results = await Promise.allSettled([
      processReminders(remind24hStart, remind24hEnd, 'reminded24h', '24小時'),
      processReminders(remind2hStart, remind2hEnd, 'reminded2h', '2小時'),
    ]);

    results.forEach((result, index) => {
      if (result.status === 'rejected') {
        console.error(`Error processing reminder group ${index}:`, result.reason);
      }
    });
  } catch (error) {
    console.error("Error sending event reminders:", error);
  }
});

async function processReminders(start: Date, end: Date, flagField: string, timeText: string) {
  const snapshot = await db.collection('dinner_events')
    .where('dateTime', '>=', start)
    .where('dateTime', '<=', end)
    .get();

  if (snapshot.empty) {
    console.log(`No events found for ${timeText} reminder.`);
    return;
  }

  let batch = db.batch();
  let operationCount = 0;

  for (const doc of snapshot.docs) {
    const eventData = doc.data();

    // Check if already reminded
    if (eventData[flagField] === true) {
      continue;
    }

    // Check if event is valid (not cancelled)
    if (eventData.status === 'cancelled') {
      continue;
    }

    const participantIds = eventData.participantIds || [];
    if (participantIds.length === 0) {
      continue;
    }

    console.log(`Sending ${timeText} reminder for event ${doc.id} to ${participantIds.length} participants.`);

    // Send notifications to participants
    // We create notification documents for each user
    const notificationsCollection = db.collection('notifications');

    for (const userId of participantIds) {
      const notificationRef = notificationsCollection.doc();
      batch.set(notificationRef, {
        userId: userId,
        type: 'event',
        title: '活動提醒',
        message: `您的聚餐活動將在${timeText}後開始，別忘了準時出席喔！`,
        actionType: 'view_event',
        actionData: doc.id,
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      operationCount++;

      // Also send push notification via FCM if token exists
      // This part assumes a separate function triggers on notification creation
      // OR we can send it directly here.
      // Ideally, the 'sendNotification' Cloud Function triggers on 'notifications' creation.
      // If not, we should implement FCM sending here too.
      // For now, creating the document is the primary requirement for "notification logic" in this system
      // as seen in other parts of the app which rely on notification documents.
    }

    // Mark event as reminded
    batch.update(doc.ref, { [flagField]: true });
    operationCount++;

    // Commit batch if it gets too large (limit is 500)
    if (operationCount >= 400) {
      await batch.commit();
      batch = db.batch(); // Re-initialize batch
      operationCount = 0;
    }
  }

  if (operationCount > 0) {
    await batch.commit();
  }
}
