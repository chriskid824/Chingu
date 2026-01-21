import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Scheduled Cloud Function to send event reminders 24 hours before the event.
 * Runs every hour.
 */
export const sendEventReminders = functions.pubsub.schedule('every 60 minutes').onRun(async (context) => {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();
    const nowMillis = now.toMillis();

    // We want to remind users ~24 hours before the event.
    // Since this runs every hour, we look for events happening between 23 and 25 hours from now.
    // This window ensures we catch events even if the scheduler is slightly off or if we missed one cycle
    // (though we also check reminderSent flag).
    const startRange = admin.firestore.Timestamp.fromMillis(nowMillis + (23 * 60 * 60 * 1000));
    const endRange = admin.firestore.Timestamp.fromMillis(nowMillis + (25 * 60 * 60 * 1000));

    console.log(`Checking for events between ${startRange.toDate().toISOString()} and ${endRange.toDate().toISOString()}`);

    try {
        const eventsSnapshot = await db.collection('dinner_events')
            .where('dateTime', '>=', startRange)
            .where('dateTime', '<=', endRange)
            .get();

        if (eventsSnapshot.empty) {
            console.log("No upcoming events found in range.");
            return null;
        }

        const batch = db.batch();
        let batchCount = 0;
        const promises: Promise<any>[] = [];

        for (const doc of eventsSnapshot.docs) {
            const event = doc.data();

            // Skip if already reminded
            if (event.reminderSent) {
                continue;
            }

            // Skip if cancelled
            if (event.status === 'cancelled') {
                continue;
            }

            // Prepare batch update
            batch.update(doc.ref, { reminderSent: true });
            batchCount++;

            const participantIds: string[] = event.participantIds || [];
            if (participantIds.length === 0) continue;

            // Fetch user tokens
            // Firestore 'in' query supports up to 10 values.
            // Dinner events have max 6 participants, so this is safe.
            // If somehow more than 10, we slice to 10 to avoid query error.
            const queryIds = participantIds.length > 10 ? participantIds.slice(0, 10) : participantIds;

            const usersSnapshot = await db.collection('users')
                .where(admin.firestore.FieldPath.documentId(), 'in', queryIds)
                .get();

            const tokens: string[] = [];
            usersSnapshot.forEach(userDoc => {
                const userData = userDoc.data();
                if (userData.fcmToken) {
                    tokens.push(userData.fcmToken);
                }
            });

            if (tokens.length > 0) {
                const eventDate = (event.dateTime as admin.firestore.Timestamp).toDate();
                // Format time (e.g., 19:00) in Taipei timezone (UTC+8)
                const timeString = eventDate.toLocaleTimeString("zh-TW", {
                    timeZone: "Asia/Taipei",
                    hour: '2-digit',
                    minute: '2-digit',
                    hour12: false
                });

                const message = {
                    notification: {
                        title: '晚餐活動提醒',
                        body: `您的晚餐活動將在明天 ${timeString} 開始！請準時出席。`,
                    },
                    data: {
                        type: 'event_reminder',
                        eventId: doc.id,
                        click_action: 'FLUTTER_NOTIFICATION_CLICK',
                    },
                    tokens: tokens,
                };

                promises.push(admin.messaging().sendEachForMulticast(message));
            }
        }

        // Commit DB updates
        if (batchCount > 0) {
            await batch.commit();
            console.log(`Marked ${batchCount} events as reminded.`);
        }

        // Wait for notifications to be sent
        if (promises.length > 0) {
            const results = await Promise.all(promises);
            let totalSuccess = 0;
            results.forEach(res => totalSuccess += res.successCount);
            console.log(`Sent reminders to participants. Total success: ${totalSuccess}`);
        }

    } catch (error) {
        console.error("Error sending event reminders:", error);
    }

    return null;
});
