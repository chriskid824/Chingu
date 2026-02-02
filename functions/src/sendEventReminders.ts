import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { getNotificationCopy, eventReminderTest } from "./notification_content";

if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Scheduled function to send event reminders 24 hours before the event.
 * Runs every 60 minutes.
 */
export const sendEventReminders = functions.pubsub
    .schedule('every 60 minutes')
    .onRun(async (context) => {
        const db = admin.firestore();
        const now = new Date();

        // Target window: 24 hours from now to 25 hours from now
        // This ensures we catch every event exactly once (since we run every hour)
        // and send the reminder roughly 24 hours before.
        const startWindow = new Date(now.getTime() + 24 * 60 * 60 * 1000);
        const endWindow = new Date(now.getTime() + 25 * 60 * 60 * 1000);

        console.log(`Checking for events between ${startWindow.toISOString()} and ${endWindow.toISOString()}`);

        try {
            // Note: Composite index required: (isReminderSent ASC, dateTime ASC)
            const eventsSnapshot = await db.collection('dinner_events')
                .where('dateTime', '>=', startWindow)
                .where('dateTime', '<=', endWindow)
                .where('isReminderSent', '==', false)
                .get();

            if (eventsSnapshot.empty) {
                console.log('No upcoming events found for reminders.');
                return null;
            }

            console.log(`Found ${eventsSnapshot.size} events to remind.`);

            const promises = eventsSnapshot.docs.map(async (doc) => {
                const eventData = doc.data();

                // Manual status check to avoid multiple inequality filter limitation in Firestore
                if (eventData.status === 'cancelled') {
                    return;
                }

                const participantIds = eventData.participantIds as string[];

                if (!participantIds || participantIds.length === 0) {
                    return;
                }

                // Get participant tokens
                // Max participants is 6, so 'in' query is safe (limit is 10)
                const usersSnapshot = await db.collection('users')
                    .where(admin.firestore.FieldPath.documentId(), 'in', participantIds)
                    .get();

                const tokens: string[] = [];
                usersSnapshot.forEach(userDoc => {
                    const userData = userDoc.data();
                    if (userData.fcmToken) {
                        tokens.push(userData.fcmToken);
                    }
                });

                if (tokens.length === 0) {
                    console.log(`No tokens found for event ${doc.id}`);
                    // Still mark as sent so we don't retry forever?
                    // Yes, logic dictates we processed it.
                    await doc.ref.update({ isReminderSent: true });
                    return;
                }

                // Prepare notification content
                const eventDate = eventData.dateTime.toDate();
                const timeString = eventDate.toLocaleTimeString('zh-TW', {
                    hour: '2-digit',
                    minute: '2-digit',
                    hour12: false
                });

                // Use the 'control' variant by default
                const { title, body } = getNotificationCopy(
                    eventReminderTest.testId,
                    'control',
                    {
                        eventName: '晚餐聚會',
                        time: timeString
                    }
                );

                const message = {
                    notification: {
                        title: title,
                        body: body,
                    },
                    data: {
                        type: 'event_reminder',
                        eventId: doc.id,
                        click_action: 'FLUTTER_NOTIFICATION_CLICK',
                    },
                    tokens: tokens,
                };

                const response = await admin.messaging().sendEachForMulticast(message);
                console.log(`Sent reminders for event ${doc.id}: ${response.successCount} success, ${response.failureCount} failed.`);

                // Mark as sent
                await doc.ref.update({ isReminderSent: true });
            });

            await Promise.all(promises);
            console.log('Finished sending event reminders.');
            return null;

        } catch (error) {
            console.error('Error sending event reminders:', error);
            throw error; // Rethrow to allow retry by Cloud Scheduler/PubSub
        }
    });
