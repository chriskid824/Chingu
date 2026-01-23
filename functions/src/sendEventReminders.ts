import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {getNotificationCopy, eventReminderTest} from "./notification_content";

// Initialize if not already done
if (admin.apps.length === 0) {
  admin.initializeApp();
}

interface DinnerEvent {
  id: string;
  dateTime: admin.firestore.Timestamp;
  restaurantName?: string;
  participantIds: string[];
  participantStatus: Record<string, string>;
  status: string;
}

const checkReminders = async (
  startTime: Date,
  endTime: Date,
  type: "24h" | "2h"
) => {
  const eventsRef = admin.firestore().collection("dinner_events");

  // Query events by time range
  const snapshot = await eventsRef
    .where("dateTime", ">=", admin.firestore.Timestamp.fromDate(startTime))
    .where("dateTime", "<", admin.firestore.Timestamp.fromDate(endTime))
    .get();

  console.log(`Found ${snapshot.size} events for ${type} reminder window.`);

  for (const doc of snapshot.docs) {
    const event = {id: doc.id, ...doc.data()} as DinnerEvent;

    // Filter confirmed events only
    if (event.status !== "confirmed") {
      console.log(`Skipping event ${event.id} (status: ${event.status})`);
      continue;
    }

    // Identify confirmed participants
    const confirmedUserIds = event.participantStatus ?
      Object.entries(event.participantStatus)
        .filter(([, status]) => status === "confirmed")
        .map(([uid]) => uid) :
      [];

    if (confirmedUserIds.length === 0) {
      continue;
    }

    // Fetch tokens
    const usersSnapshot = await admin.firestore()
      .collection("users")
      .where(admin.firestore.FieldPath.documentId(), "in", confirmedUserIds)
      .get();

    const tokens = usersSnapshot.docs
      .map((userDoc) => userDoc.data().fcmToken)
      .filter((token) => !!token);

    if (tokens.length === 0) {
      console.log(`No tokens found for event ${event.id}`);
      continue;
    }

    // Prepare content using localization
    const timeLeft = type === "24h" ? "24小時" : "2小時";
    const time = type === "24h" ? "明天" : "稍後";
    const eventName = event.restaurantName || "晚餐活動";

    const {title, body} = getNotificationCopy(
      eventReminderTest.testId,
      "control", // Using default control variant
      {eventName, time, timeLeft}
    );

    const message: admin.messaging.MulticastMessage = {
      notification: {
        title,
        body,
      },
      data: {
        type: "event_reminder",
        eventId: event.id,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      tokens,
    };

    // Send
    try {
      const response = await admin.messaging().sendEachForMulticast(message);
      console.log(
        `Sent ${type} reminders for event ${event.id}: ` +
        `${response.successCount} success, ${response.failureCount} failed.`
      );
    } catch (error) {
      console.error(
        `Error sending ${type} reminders for event ${event.id}:`,
        error
      );
    }
  }
};

export const sendEventReminders = functions.pubsub
  .schedule("every 1 hours")
  .onRun(async () => {
    const now = new Date();

    // 24h Window: Events starting between now+24h and now+25h
    const start24 = new Date(now.getTime() + 24 * 60 * 60 * 1000);
    const end24 = new Date(now.getTime() + 25 * 60 * 60 * 1000);
    await checkReminders(start24, end24, "24h");

    // 2h Window: Events starting between now+2h and now+3h
    const start2 = new Date(now.getTime() + 2 * 60 * 60 * 1000);
    const end2 = new Date(now.getTime() + 3 * 60 * 60 * 1000);
    await checkReminders(start2, end2, "2h");
  });
