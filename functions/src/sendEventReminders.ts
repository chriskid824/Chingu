import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {eventReminderTest, getNotificationCopy} from "./notification_content";

// Ensure app is initialized
if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * Scheduled function to send event reminders
 * Runs every 30 minutes
 * Sends reminders 24 hours and 2 hours before the event
 */
export const sendEventReminders = functions.pubsub.schedule("every 30 minutes").onRun(async () => {
  const now = admin.firestore.Timestamp.now();
  const nowMillis = now.toMillis();

  // Look ahead 26 hours to catch events for the 24h reminder
  const endMillis = nowMillis + 26 * 60 * 60 * 1000;
  const end = admin.firestore.Timestamp.fromMillis(endMillis);

  // Query confirmed events starting in the future (within range)
  const eventsSnapshot = await db.collection("dinner_events")
    .where("status", "==", "confirmed")
    .where("dateTime", ">", now)
    .where("dateTime", "<", end)
    .get();

  const updates: Promise<void>[] = [];

  for (const doc of eventsSnapshot.docs) {
    const eventData = doc.data();
    const eventDate = (eventData.dateTime as admin.firestore.Timestamp).toDate();
    const diffMillis = eventDate.getTime() - nowMillis;
    const hoursUntilStart = diffMillis / (1000 * 60 * 60);

    let type: "24h" | "2h" | null = null;

    if (hoursUntilStart <= 24 && hoursUntilStart > 20) {
      if (!eventData.reminder24hSent) {
        type = "24h";
      }
    } else if (hoursUntilStart <= 2 && hoursUntilStart > 0.5) {
      if (!eventData.reminder2hSent) {
        type = "2h";
      }
    }

    if (type) {
      const participantIds: string[] = eventData.participantIds || [];
      if (participantIds.length > 0) {
        updates.push(processEventReminder(doc.id, eventData, participantIds, type, eventDate));
      }
    }
  }

  await Promise.all(updates);
  return null;
});

/**
 * Process a single event reminder
 * @param {string} eventId The event ID
 * @param {admin.firestore.DocumentData} eventData The event data
 * @param {string[]} participantIds List of participant IDs
 * @param {"24h" | "2h"} type The type of reminder
 * @param {Date} eventDate The event date
 * @return {Promise<void>}
 */
async function processEventReminder(
  eventId: string,
  eventData: admin.firestore.DocumentData,
  participantIds: string[],
  type: "24h" | "2h",
  eventDate: Date
): Promise<void> {
  // Fetch participants (batch size is small, max 6)
  if (participantIds.length === 0) return;

  const usersSnapshot = await db.collection("users")
    .where(admin.firestore.FieldPath.documentId(), "in", participantIds)
    .get();

  const notifications: Promise<void>[] = [];

  for (const userDoc of usersSnapshot.docs) {
    const userData = userDoc.data();
    const fcmToken = userData.fcmToken;
    if (!fcmToken) continue;

    notifications.push(sendUserReminder(userDoc.id, fcmToken, type, eventId, eventData, eventDate));
  }

  await Promise.all(notifications);

  // Mark event as reminded to avoid duplicates
  const fieldToUpdate = type === "24h" ? "reminder24hSent" : "reminder2hSent";
  await db.collection("dinner_events").doc(eventId).update({
    [fieldToUpdate]: true,
  });
}

/**
 * Send a reminder to a specific user
 * @param {string} userId The user ID
 * @param {string} fcmToken The user's FCM token
 * @param {"24h" | "2h"} type The type of reminder
 * @param {string} eventId The event ID
 * @param {admin.firestore.DocumentData} eventData The event data
 * @param {Date} eventDate The event date
 * @return {Promise<void>}
 */
async function sendUserReminder(
  userId: string,
  fcmToken: string,
  type: "24h" | "2h",
  eventId: string,
  eventData: admin.firestore.DocumentData,
  eventDate: Date
): Promise<void> {
  // 1. Get or Assign A/B Test Variant
  const variantRef = db.collection("users").doc(userId)
    .collection("ab_test_variants").doc(eventReminderTest.testId);

  let variantId = eventReminderTest.defaultVariantId;

  try {
    const variantDoc = await variantRef.get();
    if (variantDoc.exists) {
      variantId = variantDoc.data()?.variantId || eventReminderTest.defaultVariantId;
    } else {
      // Random assignment
      const variants = eventReminderTest.variants;
      const randomIndex = Math.floor(Math.random() * variants.length);
      variantId = variants[randomIndex].variantId;

      await variantRef.set({
        variantId,
        assignedAt: admin.firestore.FieldValue.serverTimestamp(),
        testId: eventReminderTest.testId,
      });
    }
  } catch (e) {
    console.error(`Error fetching/assigning variant for user ${userId}:`, e);
    // Fallback to default
  }

  // 2. Prepare Notification Content
  const timeLeft = type === "24h" ? "24 小時" : "2 小時";

  // Format time to HH:mm (Asia/Taipei UTC+8)
  const utcHours = eventDate.getUTCHours();
  const utcMinutes = eventDate.getUTCMinutes();
  const twHours = (utcHours + 8) % 24;
  const timeStr = `${twHours.toString().padStart(2, "0")}:${utcMinutes.toString().padStart(2, "0")}`;

  const params: Record<string, string> = {
    eventName: "聚餐活動",
    time: timeStr,
    timeLeft: timeLeft,
  };

  if (eventData.district) {
    params.eventName = `${eventData.district} 聚餐`;
  }

  const {title, body} = getNotificationCopy(eventReminderTest.testId, variantId, params);

  // 3. Send Notification
  const message = {
    notification: {
      title,
      body,
    },
    token: fcmToken,
    data: {
      type: "event_reminder",
      eventId: eventId,
      reminderType: type,
      click_action: "FLUTTER_NOTIFICATION_CLICK",
    },
  };

  try {
    await admin.messaging().send(message);
  } catch (e) {
    console.error(`Failed to send reminder to ${userId}:`, e);
  }
}
