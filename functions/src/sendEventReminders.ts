import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
    admin.initializeApp();
}

export const sendEventReminders = functions.pubsub.schedule('every 1 hours').onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();
    const nowMillis = now.toMillis();

    // Target window: Events starting between 24 and 25 hours from now
    // This runs hourly, so we catch everyone once.
    const startMillis = nowMillis + (24 * 60 * 60 * 1000);
    const endMillis = nowMillis + (25 * 60 * 60 * 1000);

    const start = admin.firestore.Timestamp.fromMillis(startMillis);
    const end = admin.firestore.Timestamp.fromMillis(endMillis);

    console.log(`Checking for events between ${start.toDate().toISOString()} and ${end.toDate().toISOString()}`);

    try {
        const eventsSnapshot = await admin.firestore().collection('dinner_events')
            .where('dateTime', '>=', start)
            .where('dateTime', '<', end)
            .get();

        if (eventsSnapshot.empty) {
            console.log('No events found for reminder.');
            return null;
        }

        const promises: Promise<any>[] = [];

        for (const doc of eventsSnapshot.docs) {
            const eventData = doc.data();

            // Optional: Check status. Assuming we remind for all valid events.
            if (eventData.status === 'cancelled') continue;

            const participantIds: string[] = eventData.participantIds || [];

            if (participantIds.length === 0) continue;

            // Fetch users to get tokens
            // Firestore 'in' query supports up to 10 items.
            // Participants are max 6, so this is safe.
            promises.push((async () => {
                try {
                    const usersSnapshot = await admin.firestore().collection('users')
                        .where(admin.firestore.FieldPath.documentId(), 'in', participantIds)
                        .get();

                    const tokens: string[] = [];
                    usersSnapshot.docs.forEach(userDoc => {
                        const userData = userDoc.data();
                        if (userData.fcmToken) {
                            tokens.push(userData.fcmToken);
                        }
                    });

                    if (tokens.length > 0) {
                        const message = {
                            notification: {
                                title: '活動提醒',
                                body: `您的晚餐活動將在明天 ${eventData.city} ${eventData.district} 舉行，別忘了參加喔！`,
                            },
                            data: {
                                actionType: 'view_event',
                                actionData: doc.id, // Event ID
                                eventId: doc.id,
                            },
                            tokens: tokens,
                        };

                        const response = await admin.messaging().sendEachForMulticast(message);
                        console.log(`Sent reminders for event ${doc.id}: ${response.successCount} success, ${response.failureCount} failure.`);
                    }
                } catch (e) {
                    console.error(`Error processing event ${doc.id}:`, e);
                }
            })());
        }

        await Promise.all(promises);
        return null;

    } catch (error) {
        console.error('Error sending event reminders:', error);
        return null;
    }
});
