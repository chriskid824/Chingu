import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Ensure Firebase Admin is initialized
if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Scheduled function to send reminders for dinner events.
 * Runs every hour to check for events starting in approximately 24 hours.
 */
export const sendEventReminders = functions.pubsub.schedule("every 1 hours").onRun(async (context) => {
    const db = admin.firestore();
    const messaging = admin.messaging();
    const now = admin.firestore.Timestamp.now();

    // Target window: Events starting between 23 and 25 hours from now.
    // This gives a 2-hour window. Since we run every hour, we should catch them.
    // The `reminderSent` flag prevents duplicate sends.
    const startWindow = new Date(now.toMillis() + (23 * 60 * 60 * 1000));
    const endWindow = new Date(now.toMillis() + (25 * 60 * 60 * 1000));

    console.log(`Checking for events between ${startWindow.toISOString()} and ${endWindow.toISOString()}`);

    try {
        const eventsSnapshot = await db.collection("dinner_events")
            .where("dateTime", ">=", startWindow)
            .where("dateTime", "<=", endWindow)
            .where("reminderSent", "==", false)
            .get();

        if (eventsSnapshot.empty) {
            console.log("No upcoming events found for reminders.");
            return null;
        }

        console.log(`Found ${eventsSnapshot.size} events to remind.`);

        const batch = db.batch();
        let notificationCount = 0;

        for (const doc of eventsSnapshot.docs) {
            const eventData = doc.data();
            const participantIds: string[] = eventData.participantIds || [];

            if (participantIds.length === 0) {
                console.log(`Event ${doc.id} has no participants.`);
                // Mark as sent anyway to avoid reprocessing
                batch.update(doc.ref, { reminderSent: true });
                continue;
            }

            // Fetch users to get FCM tokens
            // dinner events are capped at 6 participants, so 'in' query (limit 10) is safe
            const usersSnapshot = await db.collection("users")
                .where(admin.firestore.FieldPath.documentId(), "in", participantIds)
                .get();

            const tokens: string[] = [];
            usersSnapshot.forEach(userDoc => {
                const userData = userDoc.data();
                if (userData.fcmToken) {
                    tokens.push(userData.fcmToken);
                }
            });

            if (tokens.length > 0) {
                const message = {
                    notification: {
                        title: "Dinner Event Reminder",
                        body: "Don't forget! Your dinner event is tomorrow!",
                    },
                    tokens: tokens,
                };

                const response = await messaging.sendEachForMulticast(message);
                notificationCount += response.successCount;
                console.log(`Sent reminders for event ${doc.id}: ${response.successCount} success, ${response.failureCount} failed.`);
            }

            // Update the event to mark reminder as sent
            batch.update(doc.ref, { reminderSent: true });
        }

        await batch.commit();
        console.log(`Total reminders sent: ${notificationCount}`);
        return null;

    } catch (error) {
        console.error("Error sending event reminders:", error);
        return null;
    }
});
