import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { getNotificationCopy, eventReminderTest } from "./notification_content";

// Ensure admin is initialized
if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Scheduled function to send event reminders
 * Runs every 30 minutes to check for upcoming events
 */
export const sendEventReminders = functions.pubsub.schedule('every 30 minutes').onRun(async (context) => {
    // Use scheduled time to avoid drift
    const scheduledTime = context.timestamp ? new Date(context.timestamp) : new Date();
    const nowMillis = scheduledTime.getTime();

    // Calculate windows
    // 24 hours: [now + 24h, now + 24h + 30m]
    const twentyFourHours = 24 * 60 * 60 * 1000;
    const start24h = new Date(nowMillis + twentyFourHours);
    const end24h = new Date(nowMillis + twentyFourHours + 30 * 60 * 1000); // + 30 mins

    // 2 hours: [now + 2h, now + 2h + 30m]
    const twoHours = 2 * 60 * 60 * 1000;
    const start2h = new Date(nowMillis + twoHours);
    const end2h = new Date(nowMillis + twoHours + 30 * 60 * 1000); // + 30 mins

    const db = admin.firestore();

    try {
        // Run queries in parallel
        const [events24h, events2h] = await Promise.all([
            db.collection('dinner_events')
              .where('dateTime', '>=', start24h)
              .where('dateTime', '<', end24h)
              .where('status', 'in', ['confirmed', 'pending'])
              .get(),
            db.collection('dinner_events')
              .where('dateTime', '>=', start2h)
              .where('dateTime', '<', end2h)
              .where('status', 'in', ['confirmed'])
              .get()
        ]);

        console.log(`Found ${events24h.size} events for 24h reminder and ${events2h.size} events for 2h reminder`);

        // Process 24h reminders
        await processReminders(events24h, '24h');

        // Process 2h reminders
        await processReminders(events2h, '2h');

    } catch (error) {
        console.error("Error in sendEventReminders:", error);
    }

    return null;
});

async function processReminders(
    snapshot: admin.firestore.QuerySnapshot,
    type: '24h' | '2h'
) {
    if (snapshot.empty) return;

    for (const doc of snapshot.docs) {
        const event = doc.data();
        const eventId = doc.id;
        const participantIds: string[] = event.participantIds || [];

        if (participantIds.length === 0) continue;

        try {
            // Fetch users
            // Note: participantIds is limited to 6 (max participants per event),
            // so using 'in' query is safe (limit is 10 or 30).
            const usersSnapshot = await admin.firestore().collection('users')
                .where(admin.firestore.FieldPath.documentId(), 'in', participantIds)
                .get();

            const batchMessages: admin.messaging.Message[] = [];

            usersSnapshot.forEach((userDoc) => {
                const user = userDoc.data();
                const fcmToken = user.fcmToken;

                if (!fcmToken) return;

                // Determine notification content
                const timeLeft = type === '24h' ? '24小時' : '2小時';

                // Format time (assuming Taipei time for now, or use event city/timezone if available)
                const eventDate = (event.dateTime as admin.firestore.Timestamp).toDate();
                const eventTime = eventDate.toLocaleString('zh-TW', {
                    timeZone: 'Asia/Taipei',
                    hour: '2-digit',
                    minute: '2-digit',
                    hour12: false
                });

                // Use restaurant name if available, otherwise generic
                const eventName = event.restaurantName || '晚餐活動';

                const variantId = 'control'; // Default to control variant

                const { title, body } = getNotificationCopy(
                    eventReminderTest.testId,
                    variantId,
                    {
                        eventName: eventName,
                        time: eventTime,
                        timeLeft: timeLeft
                    }
                );

                batchMessages.push({
                    token: fcmToken,
                    notification: {
                        title,
                        body,
                    },
                    data: {
                        type: 'event_reminder',
                        actionType: 'view_event',
                        actionData: eventId,
                        click_action: 'FLUTTER_NOTIFICATION_CLICK'
                    }
                });
            });

            if (batchMessages.length > 0) {
               await admin.messaging().sendEach(batchMessages);
               console.log(`Sent ${batchMessages.length} reminders (${type}) for event ${eventId}`);
            }
        } catch (error) {
            console.error(`Error processing reminder for event ${eventId}:`, error);
        }
    }
}
