import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Cloud Function triggered by Cloud Scheduler every hour
 * Checks for dinner events starting in 24 hours and sends reminders
 */
export const sendEventReminders = functions.pubsub.schedule('every 1 hours').onRun(async (context) => {
    const db = admin.firestore();
    const messaging = admin.messaging();

    const now = admin.firestore.Timestamp.now();
    const nowMillis = now.toMillis();

    // Target window: 24h to 25h from now
    // We check for events that start between 24 and 25 hours from now
    const startWindow = admin.firestore.Timestamp.fromMillis(nowMillis + 24 * 60 * 60 * 1000);
    const endWindow = admin.firestore.Timestamp.fromMillis(nowMillis + 25 * 60 * 60 * 1000);

    console.log(`Checking for events between ${startWindow.toDate()} and ${endWindow.toDate()}`);

    try {
        const eventsSnapshot = await db.collection('dinner_events')
            .where('dateTime', '>=', startWindow)
            .where('dateTime', '<', endWindow)
            .get();

        if (eventsSnapshot.empty) {
            console.log('No upcoming events found for reminders.');
            return;
        }

        const events = eventsSnapshot.docs;
        let notificationCount = 0;

        for (const eventDoc of events) {
            const eventData = eventDoc.data();
            const participantIds: string[] = eventData.participantIds || [];

            if (participantIds.length === 0) continue;

            // Fetch users to get FCM tokens
            // Batching might be needed if many participants, but max 6 per table.
            const usersSnapshot = await db.collection('users')
                .where(admin.firestore.FieldPath.documentId(), 'in', participantIds)
                .get();

            const tokens: string[] = [];
            usersSnapshot.forEach(doc => {
                const userData = doc.data();
                if (userData.fcmToken) {
                    tokens.push(userData.fcmToken);
                }
            });

            if (tokens.length > 0) {
                const message = {
                    notification: {
                        title: '晚餐活動提醒',
                        body: '您明天有一個晚餐活動，別忘了參加！',
                    },
                    data: {
                        actionType: 'view_event',
                        actionData: eventDoc.id,
                        click_action: 'FLUTTER_NOTIFICATION_CLICK',
                    },
                    tokens: tokens,
                };

                const response = await messaging.sendEachForMulticast(message);
                notificationCount += response.successCount;

                if (response.failureCount > 0) {
                     console.log(`Failed to send ${response.failureCount} reminders for event ${eventDoc.id}`);
                }
            }
        }

        console.log(`Sent ${notificationCount} event reminders.`);

    } catch (error) {
        console.error('Error sending event reminders:', error);
    }
});
