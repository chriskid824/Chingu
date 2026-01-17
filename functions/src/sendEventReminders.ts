import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Ensure app is initialized
if (admin.apps.length === 0) {
  admin.initializeApp();
}

/**
 * Scheduled function to send reminders for dinner events.
 * Runs every 60 minutes.
 * Sends reminders 24 hours and 2 hours before the event.
 */
export const sendEventReminders = functions.pubsub.schedule("every 60 minutes").onRun(async () => {
  const db = admin.firestore();
  const now = new Date();

  console.log("Running sendEventReminders at", now.toISOString());

  // Calculate time windows
  // We look for events happening between [now + 24h, now + 25h)
  // This assumes the job runs roughly every hour.
  // To be safe against slight delays, we could widen the window slightly,
  // but strict hourly windows are usually fine if we track 'remindersSent'.

  // Window for 24h reminder
  const start24h = new Date(now.getTime() + 24 * 60 * 60 * 1000);
  const end24h = new Date(start24h.getTime() + 60 * 60 * 1000);

  // Window for 2h reminder
  const start2h = new Date(now.getTime() + 2 * 60 * 60 * 1000);
  const end2h = new Date(start2h.getTime() + 60 * 60 * 1000);

  try {
    await Promise.all([
      processEvents(db, start24h, end24h, "24h"),
      processEvents(db, start2h, end2h, "2h"),
    ]);
    console.log("Finished sending event reminders");
  } catch (error) {
    console.error("Error sending event reminders:", error);
  }
});

/**
 * Process events in a specific time range to send reminders.
 * @param {admin.firestore.Firestore} db Firestore instance
 * @param {Date} start Start of time window
 * @param {Date} end End of time window
 * @param {string} type Type of reminder ('24h' or '2h')
 */
async function processEvents(
  db: admin.firestore.Firestore,
  start: Date,
  end: Date,
  type: "24h" | "2h"
) {
  // Query confirmed events in the time range
  const snapshot = await db.collection("dinner_events")
    .where("status", "==", "confirmed")
    .where("dateTime", ">=", start)
    .where("dateTime", "<", end)
    .get();

  if (snapshot.empty) {
    const msg = `No confirmed events found for ${type} reminder between ` +
      `${start.toISOString()} and ${end.toISOString()}`;
    console.log(msg);
    return;
  }

  console.log(`Found ${snapshot.size} events for ${type} reminder`);

  const promises = snapshot.docs.map(async (doc) => {
    const data = doc.data();

    // Check if reminder was already sent
    if (data.remindersSent && data.remindersSent[type]) {
      console.log(`Skipping event ${doc.id}: ${type} reminder already sent`);
      return;
    }

    // Get confirmed participants
    const participantStatus = data.participantStatus || {};
    const confirmedUserIds = Object.keys(participantStatus).filter(
      (uid) => participantStatus[uid] === "confirmed"
    );

    if (confirmedUserIds.length === 0) {
      console.log(`Skipping event ${doc.id}: No confirmed participants`);
      return;
    }

    // Fetch user tokens
    const tokens = await getTokensForUsers(db, confirmedUserIds);

    if (tokens.length === 0) {
      console.log(`Skipping event ${doc.id}: No valid tokens found`);
      return;
    }

    // Prepare notification content
    const title = "活動提醒";
    const body = type === "24h" ?
      "您的聚餐活動將在 24 小時後開始，請準時出席！" :
      "您的聚餐活動即將在 2 小時後開始，別忘了出發喔！";

    // Send notification
    const message: admin.messaging.MulticastMessage = {
      notification: {
        title,
        body,
      },
      data: {
        type: "event_reminder",
        eventId: doc.id,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      tokens: tokens,
    };

    const response = await admin.messaging().sendEachForMulticast(message);
    const logMsg = `Sent ${type} reminders for event ${doc.id}: ` +
      `${response.successCount} success, ${response.failureCount} failed`;
    console.log(logMsg);

    // Mark as sent
    await doc.ref.set({
      remindersSent: {
        [type]: true,
      },
    }, {merge: true});
  });

  await Promise.all(promises);
}

/**
 * Fetch FCM tokens for a list of user IDs.
 * @param {admin.firestore.Firestore} db Firestore instance
 * @param {string[]} userIds List of user IDs
 * @return {Promise<string[]>} List of FCM tokens
 */
async function getTokensForUsers(db: admin.firestore.Firestore, userIds: string[]): Promise<string[]> {
  if (userIds.length === 0) return [];

  // Firestore 'in' query supports up to 30 items
  const chunks = [];
  for (let i = 0; i < userIds.length; i += 30) {
    chunks.push(userIds.slice(i, i + 30));
  }

  let tokens: string[] = [];

  for (const chunk of chunks) {
    const snapshot = await db.collection("users")
      .where(admin.firestore.FieldPath.documentId(), "in", chunk)
      .get();

    const chunkTokens = snapshot.docs
      .map((doc) => doc.data().fcmToken)
      .filter((token) => token && typeof token === "string"); // Ensure token exists and is string

    tokens = tokens.concat(chunkTokens);
  }

  return tokens;
}
