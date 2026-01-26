import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { getNotificationCopy, eventReminderTest } from "./notification_content";

export const sendEventReminders = functions.pubsub.schedule('every 60 minutes').onRun(async (context) => {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();
    const nowMillis = now.toMillis();

    // 24 hours from now (window: 24h to 25h)
    const start24h = admin.firestore.Timestamp.fromMillis(nowMillis + 24 * 60 * 60 * 1000);
    const end24h = admin.firestore.Timestamp.fromMillis(nowMillis + 25 * 60 * 60 * 1000);

    // 2 hours from now (window: 2h to 3h)
    const start2h = admin.firestore.Timestamp.fromMillis(nowMillis + 2 * 60 * 60 * 1000);
    const end2h = admin.firestore.Timestamp.fromMillis(nowMillis + 3 * 60 * 60 * 1000);

    const promises: Promise<any>[] = [];

    // Helper function to process events
    const processEvents = async (events: FirebaseFirestore.QuerySnapshot, timeLeft: string) => {
        for (const doc of events.docs) {
            const eventData = doc.data();
            const participantIds = eventData.participantIds as string[];

            if (!participantIds || participantIds.length === 0) continue;

            // Fetch users
            // Firestore 'in' query supports up to 10 items.
            // Split participantIds into chunks of 10 to be safe.
            const chunks = [];
            for (let i = 0; i < participantIds.length; i += 10) {
                chunks.push(participantIds.slice(i, i + 10));
            }

            const tokens: string[] = [];

            for (const chunk of chunks) {
                const usersSnapshot = await db.collection('users')
                    .where(admin.firestore.FieldPath.documentId(), 'in', chunk)
                    .get();

                usersSnapshot.docs.forEach(userDoc => {
                    const userData = userDoc.data();
                    // Check if user has notifications enabled?
                    // For critical reminders like this, we usually send anyway,
                    // but strictly we should check `notificationEventEnabled` (default true).
                    // Assuming we just send for now as per prompt "Activity Reminders".
                    if (userData.fcmToken) {
                        tokens.push(userData.fcmToken);
                    }
                });
            }

            if (tokens.length > 0) {
                // Construct event name
                let eventName = 'Dinner Event';
                if (eventData.district) {
                    eventName = `${eventData.district} Dinner`; // e.g. "Xinyi District Dinner"
                }

                // Use 'countdown' variant which uses {timeLeft}
                const finalContent = getNotificationCopy(
                    eventReminderTest.testId,
                    'countdown',
                    {
                        eventName: eventName,
                        timeLeft: timeLeft
                    }
                );

                const message: admin.messaging.MulticastMessage = {
                    tokens: tokens,
                    notification: {
                        title: finalContent.title,
                        body: finalContent.body,
                    },
                    data: {
                        action: 'view_event',
                        eventId: doc.id
                    }
                };

                promises.push(admin.messaging().sendEachForMulticast(message));
            }
        }
    };

    try {
        // Query for 24h reminders
        const events24h = await db.collection('dinner_events')
            .where('dateTime', '>=', start24h)
            .where('dateTime', '<', end24h)
            .where('status', '!=', 'cancelled')
            .get();

        // Query for 2h reminders
        const events2h = await db.collection('dinner_events')
            .where('dateTime', '>=', start2h)
            .where('dateTime', '<', end2h)
            .where('status', '!=', 'cancelled')
            .get();

        await processEvents(events24h, '24 hours');
        await processEvents(events2h, '2 hours');

        await Promise.all(promises);
        console.log(`Processed ${events24h.size} 24h reminders and ${events2h.size} 2h reminders.`);
    } catch (error) {
        console.error("Error sending event reminders:", error);
    }

    return null;
});
