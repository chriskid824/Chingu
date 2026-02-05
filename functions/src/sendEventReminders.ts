import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { getNotificationCopy, eventReminderTest } from "./notification_content";

/**
 * Cloud Scheduler triggered function to send event reminders
 * Runs every hour to check for upcoming dinner events (24h before)
 */
export const sendEventReminders = functions.pubsub.schedule("0 * * * *")
    .timeZone("Asia/Taipei") // Set timezone to Taipei
    .onRun(async (context) => {
        const db = admin.firestore();
        const now = admin.firestore.Timestamp.now();
        const nowMillis = now.toMillis();

        // Window: 23h to 25h from now
        // This ensures we catch events that are roughly 24h away, running every hour
        const startMillis = nowMillis + (23 * 60 * 60 * 1000);
        const endMillis = nowMillis + (25 * 60 * 60 * 1000);

        const start = admin.firestore.Timestamp.fromMillis(startMillis);
        const end = admin.firestore.Timestamp.fromMillis(endMillis);

        console.log(`Checking for events between ${start.toDate().toISOString()} and ${end.toDate().toISOString()}`);

        try {
            const eventsSnapshot = await db.collection("dinner_events")
                .where("dateTime", ">=", start)
                .where("dateTime", "<=", end)
                .get();

            if (eventsSnapshot.empty) {
                console.log("No upcoming events found in the window.");
                return null;
            }

            console.log(`Found ${eventsSnapshot.size} potential events.`);

            const promises = eventsSnapshot.docs.map(async (doc) => {
                const data = doc.data();

                // Skip if reminder already sent
                if (data.isReminderSent === true) {
                    return;
                }

                // Skip cancelled events
                if (data.status === 'cancelled') {
                    return;
                }

                const participantIds = data.participantIds as string[];
                if (!participantIds || participantIds.length === 0) {
                    return;
                }

                // Get tokens for all participants
                // Note: MAX_PARTICIPANTS is 6, so 'in' query (limit 30) is safe here.
                const userDocs = await db.collection("users")
                    .where(admin.firestore.FieldPath.documentId(), "in", participantIds)
                    .get();

                const tokens: string[] = [];
                userDocs.forEach(userDoc => {
                    const userData = userDoc.data();
                    if (userData.fcmToken) {
                        tokens.push(userData.fcmToken);
                    }
                });

                if (tokens.length === 0) {
                    console.log(`No tokens found for event ${doc.id}`);
                    return;
                }

                // Generate notification content
                // Use default 'control' variant for now.
                // eventReminderTest is the production configuration for this notification type.
                const eventTime = (data.dateTime as admin.firestore.Timestamp).toDate();
                const timeString = eventTime.toLocaleTimeString('zh-TW', {
                    hour: '2-digit',
                    minute: '2-digit',
                    hour12: false
                });

                const { title, body } = getNotificationCopy(
                    eventReminderTest.testId,
                    "control", // Default variant
                    {
                        eventName: "晚餐聚會",
                        time: timeString,
                    }
                );

                // Send notifications
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
                    tokens: tokens,
                };

                const response = await admin.messaging().sendEachForMulticast(message);
                console.log(`Sent reminders for event ${doc.id}: ${response.successCount} success, ${response.failureCount} failed.`);

                // Mark as sent
                await doc.ref.update({
                    isReminderSent: true
                });
            });

            await Promise.all(promises);
            console.log("Finished sending event reminders.");
            return null;

        } catch (error) {
            console.error("Error sending event reminders:", error);
            return null;
        }
    });
