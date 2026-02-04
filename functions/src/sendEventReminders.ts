import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { eventReminderTest, getNotificationCopy } from "./notification_content";

// Ensure app is initialized
if (!admin.apps.length) {
    admin.initializeApp();
}

/**
 * Scheduled function to send event reminders 24 hours before the event.
 * Runs every hour.
 */
export const sendEventReminders = functions.pubsub
    .schedule("every 1 hours")
    .onRun(async (context) => {
        const now = new Date();
        // Check for events starting in 24 hours (with a 1-hour window)
        // We look for events where dateTime is in [now + 24h, now + 25h)
        const startWindow = new Date(now.getTime() + 24 * 60 * 60 * 1000);
        const endWindow = new Date(now.getTime() + 25 * 60 * 60 * 1000);

        console.log(`[Event Reminder] Checking events between ${startWindow.toISOString()} and ${endWindow.toISOString()}`);

        try {
            const eventsSnapshot = await admin.firestore()
                .collection("dinner_events")
                .where("dateTime", ">=", admin.firestore.Timestamp.fromDate(startWindow))
                .where("dateTime", "<", admin.firestore.Timestamp.fromDate(endWindow))
                .get();

            if (eventsSnapshot.empty) {
                console.log("[Event Reminder] No events found in this window.");
                return;
            }

            console.log(`[Event Reminder] Found ${eventsSnapshot.size} events.`);

            const promises = eventsSnapshot.docs.map(async (doc) => {
                const event = doc.data();
                const eventId = doc.id;

                // Skip cancelled or completed events
                if (event.status === "cancelled" || event.status === "completed") {
                    return;
                }

                const participantIds: string[] = event.participantIds || [];
                if (participantIds.length === 0) return;

                // Fetch users to get FCM tokens
                // Firestore 'in' query supports up to 30 items.
                // Participants are max 6, so it's safe.
                const usersSnapshot = await admin.firestore()
                    .collection("users")
                    .where(admin.firestore.FieldPath.documentId(), "in", participantIds)
                    .get();

                const tokens: string[] = [];
                usersSnapshot.forEach((userDoc) => {
                    const userData = userDoc.data();
                    if (userData.fcmToken) {
                        tokens.push(userData.fcmToken);
                    }
                });

                if (tokens.length === 0) {
                    console.log(`[Event Reminder] No tokens found for event ${eventId}`);
                    return;
                }

                // Prepare notification content
                // Use default variant
                const eventTime = (event.dateTime as admin.firestore.Timestamp).toDate();
                const timeString = eventTime.toLocaleTimeString("zh-TW", {
                    hour: "2-digit",
                    minute: "2-digit",
                    hour12: false,
                    timeZone: "Asia/Taipei", // Default to Taipei time
                });

                const { title, body } = getNotificationCopy(
                    eventReminderTest.testId,
                    eventReminderTest.defaultVariantId,
                    {
                        eventName: "晚餐聚會", // Or construct from city/district
                        time: timeString,
                        timeLeft: "24小時",
                    }
                );

                const message: admin.messaging.MulticastMessage = {
                    tokens: tokens,
                    notification: {
                        title,
                        body,
                    },
                    data: {
                        type: "event_reminder",
                        eventId: eventId,
                        click_action: "FLUTTER_NOTIFICATION_CLICK",
                    },
                };

                const response = await admin.messaging().sendEachForMulticast(message);
                console.log(`[Event Reminder] Sent reminders for event ${eventId}: ${response.successCount} success, ${response.failureCount} failure.`);

                // Log failures
                if (response.failureCount > 0) {
                     response.responses.forEach((resp, idx) => {
                        if (!resp.success) {
                            console.error(`[Event Reminder] Error sending to token ${tokens[idx]}:`, resp.error);
                        }
                    });
                }
            });

            await Promise.all(promises);
            console.log("[Event Reminder] Finished processing events.");

        } catch (error) {
            console.error("[Event Reminder] Error:", error);
        }
    });
