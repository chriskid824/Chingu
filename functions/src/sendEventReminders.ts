import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Ensure admin is initialized
if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Scheduled function to send event reminders 24 hours before the event.
 * Runs every hour.
 */
export const sendEventReminders = functions.pubsub
    .schedule("every 60 minutes")
    .onRun(async (context) => {
        const now = new Date();
        // Calculate the window: 24 hours from now (inclusive) to 25 hours from now (exclusive)
        const start = new Date(now.getTime() + 24 * 60 * 60 * 1000);
        const end = new Date(now.getTime() + 25 * 60 * 60 * 1000);

        console.log(`Checking for events between ${start.toISOString()} and ${end.toISOString()}`);

        try {
            // Remove 'status' filter from query to avoid composite index requirement
            const eventsSnapshot = await admin.firestore()
                .collection("dinner_events")
                .where("dateTime", ">=", start)
                .where("dateTime", "<", end)
                .get();

            if (eventsSnapshot.empty) {
                console.log("No events found for reminder.");
                return;
            }

            console.log(`Found ${eventsSnapshot.size} events.`);

            const sendPromises = eventsSnapshot.docs.map(async (eventDoc) => {
                const eventData = eventDoc.data();

                // Idempotency check: Skip if already reminded
                if (eventData.reminded24h) {
                    return;
                }

                // In-memory status filter
                if (!['pending', 'confirmed'].includes(eventData.status)) {
                    return;
                }

                const participantIds: string[] = eventData.participantIds || [];

                if (participantIds.length === 0) {
                    // Mark as processed even if no participants to avoid re-checking
                    await eventDoc.ref.update({ reminded24h: true });
                    return;
                }

                // Max participants is small (6), so this query is safe.
                const usersSnapshot = await admin.firestore()
                    .collection("users")
                    .where(admin.firestore.FieldPath.documentId(), "in", participantIds)
                    .get();

                const tokens: string[] = [];
                usersSnapshot.docs.forEach((userDoc) => {
                    const userData = userDoc.data();
                    if (userData.fcmToken) {
                        tokens.push(userData.fcmToken);
                    }
                });

                if (tokens.length === 0) {
                    // Mark as processed
                    await eventDoc.ref.update({ reminded24h: true });
                    return;
                }

                const restaurantName = eventData.restaurantName || "指定地點";

                const message = {
                    notification: {
                        title: "活動提醒",
                        body: `您的聚餐活動將在明天舉行！地點：${restaurantName}，請準時出席。`,
                    },
                    data: {
                        type: "event_reminder",
                        eventId: eventDoc.id,
                        click_action: "FLUTTER_NOTIFICATION_CLICK",
                    },
                    tokens: tokens,
                };

                const response = await admin.messaging().sendEachForMulticast(message);
                console.log(`Sent reminders for event ${eventDoc.id}: ${response.successCount} success, ${response.failureCount} failure.`);

                // Update the event to mark as reminded
                await eventDoc.ref.update({ reminded24h: true });
            });

            await Promise.all(sendPromises);

        } catch (error) {
            console.error("Error sending event reminders:", error);
        }
    });
