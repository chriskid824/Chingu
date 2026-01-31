import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Conditionally initialize admin to avoid "already exists" errors
if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Cloud Function to send reminders for dinner events.
 * Runs every hour.
 * Checks for events starting between 23.5 and 24.5 hours from now.
 * Sends notifications to all confirmed participants.
 */
export const sendEventReminders = functions.pubsub.schedule("0 * * * *").onRun(async (context) => {
    const db = admin.firestore();
    const now = new Date();

    // Calculate the time window (24 hours from now, +/- 30 minutes)
    // We check for events starting roughly 24 hours from now.
    // The query range [23.5h, 24.5h] ensures we catch the event when the cron runs near the 24h mark.
    const twentyFourHours = 24 * 60 * 60 * 1000;
    const window = 30 * 60 * 1000; // 30 minutes

    const start = new Date(now.getTime() + twentyFourHours - window);
    const end = new Date(now.getTime() + twentyFourHours + window);

    console.log(`Checking for events between ${start.toISOString()} and ${end.toISOString()}`);

    try {
        const eventsSnapshot = await db.collection("dinner_events")
            .where("dateTime", ">=", start)
            .where("dateTime", "<=", end)
            .get();

        // Filter in memory for isReminderSent to avoid composite index requirement immediately
        const eventsToRemind = eventsSnapshot.docs.filter(doc => {
            const data = doc.data();
            // Check if reminder not sent, and status is confirmed (or at least not cancelled)
            // Assuming 'confirmed' is the target status, but 'pending' events occurring tomorrow might also need attention.
            // Requirement says "Activity reminder". Safest to remind if not cancelled.
            return !data.isReminderSent && data.status !== 'cancelled';
        });

        console.log(`Found ${eventsToRemind.length} events to remind.`);

        for (const eventDoc of eventsToRemind) {
            const eventData = eventDoc.data();
            const participantIds: string[] = eventData.participantIds || [];

            if (participantIds.length === 0) continue;

            // Get user tokens
            // Firestore 'in' query supports up to 10 items.
            // DinnerEvent has max 6 participants.
            const usersSnapshot = await db.collection("users")
                .where(admin.firestore.FieldPath.documentId(), "in", participantIds)
                .get();

            const tokens: string[] = [];
            usersSnapshot.docs.forEach(userDoc => {
                const userData = userDoc.data();
                if (userData.fcmToken) {
                    tokens.push(userData.fcmToken);
                }
            });

            if (tokens.length > 0) {
                // Format time for display (Taipei Time)
                // Note: toDate() returns a Date object which prints in server local time (usually UTC)
                // We want to display something friendly.
                // Using simple "Tomorrow" message to avoid timezone confusion if Intl is not robust.

                const message = {
                    notification: {
                        title: "活動提醒",
                        body: "您的晚餐聚會將在明天開始，別忘了準時出席喔！",
                    },
                    data: {
                        type: "dinner_event_reminder",
                        eventId: eventDoc.id,
                        click_action: "FLUTTER_NOTIFICATION_CLICK",
                    },
                    tokens: tokens,
                };

                const response = await admin.messaging().sendEachForMulticast(message);
                console.log(`Sent reminders for event ${eventDoc.id}: ${response.successCount} success, ${response.failureCount} failure.`);
            }

            // Mark as sent
            await eventDoc.ref.update({
                isReminderSent: true
            });
        }

    } catch (error) {
        console.error("Error sending event reminders:", error);
    }
});
