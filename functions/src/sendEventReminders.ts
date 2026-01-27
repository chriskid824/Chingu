import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { eventReminderTest, getNotificationCopy } from "./notification_content";

/**
 * Cloud Function to send event reminders 24 hours before the event.
 * Runs every 60 minutes.
 */
export const sendEventReminders = functions.pubsub
    .schedule("every 60 minutes")
    .onRun(async (context) => {
        const db = admin.firestore();
        const now = admin.firestore.Timestamp.now();
        const nowMillis = now.toMillis();

        // Target time window: 23 to 25 hours from now
        // This covers the 24h mark with a buffer to ensure we don't miss events due to schedule jitter
        // We rely on `isReminderSent` flag to prevent duplicate notifications
        const startWindow = admin.firestore.Timestamp.fromMillis(nowMillis + 23 * 60 * 60 * 1000);
        const endWindow = admin.firestore.Timestamp.fromMillis(nowMillis + 25 * 60 * 60 * 1000);

        console.log(`Checking for events between ${startWindow.toDate()} and ${endWindow.toDate()}`);

        try {
            // Query only by time to avoid missing composite indexes
            // We filter status and isReminderSent in memory
            const eventsSnapshot = await db.collection("dinner_events")
                .where("dateTime", ">=", startWindow)
                .where("dateTime", "<=", endWindow)
                .get();

            const batch = db.batch();
            let updateCount = 0;

            for (const doc of eventsSnapshot.docs) {
                const eventData = doc.data();

                // Only remind for confirmed events
                if (eventData.status !== 'confirmed') {
                    continue;
                }

                // Skip if reminder already sent
                if (eventData.isReminderSent === true) {
                    continue;
                }

                const participantIds = eventData.participantIds as string[];
                if (!participantIds || participantIds.length === 0) {
                    continue;
                }

                console.log(`Processing event ${doc.id} with ${participantIds.length} participants`);

                // Get participants' tokens
                // Note: participantIds length is max 6, so 'in' query is safe
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
                    const eventName = `${eventData.city}${eventData.district}晚餐`;
                    const timeString = eventData.dateTime.toDate().toLocaleString('zh-TW', {
                        hour: '2-digit',
                        minute: '2-digit',
                        hour12: false
                    });

                    // Prepare notification content
                    // Using 'control' variant for now
                    const { title, body } = getNotificationCopy(
                        eventReminderTest.testId,
                        'control',
                        {
                            eventName: eventName,
                            time: timeString,
                        }
                    );

                    const message = {
                        notification: {
                            title,
                            body,
                        },
                        data: {
                            type: 'event_reminder',
                            eventId: doc.id,
                            click_action: 'FLUTTER_NOTIFICATION_CLICK',
                        },
                        tokens: tokens,
                    };

                    const response = await admin.messaging().sendEachForMulticast(message);
                    console.log(`Sent reminders for event ${doc.id}: ${response.successCount} success, ${response.failureCount} failure`);
                }

                // Mark as sent
                batch.update(doc.ref, { isReminderSent: true });
                updateCount++;
            }

            if (updateCount > 0) {
                await batch.commit();
                console.log(`Updated ${updateCount} events as reminded.`);
            }

        } catch (error) {
            console.error("Error sending event reminders:", error);
            throw error;
        }
    });
