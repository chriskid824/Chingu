import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Scheduled function to send reminders for dinner events 24 hours in advance.
 * Runs every hour.
 */
export const sendEventReminders = functions.pubsub
    .schedule("every 1 hours")
    .timeZone("Asia/Taipei") // Ensure the schedule runs in Taipei time (optional but good for log consistency)
    .onRun(async (context) => {
        const db = admin.firestore();
        const now = new Date();

        // Calculate the window: events starting between 23h and 25h from now.
        // This 2-hour window + 'reminderSent' flag ensures we don't miss events
        // due to slight timing skews and don't send duplicates.
        const startWindow = new Date(now.getTime() + 23 * 60 * 60 * 1000);
        const endWindow = new Date(now.getTime() + 25 * 60 * 60 * 1000);

        console.log(`Checking for events between ${startWindow.toISOString()} and ${endWindow.toISOString()}`);

        try {
            // Query for confirmed events in the time window
            const eventsSnapshot = await db
                .collection("dinner_events")
                .where("status", "==", "confirmed")
                .where("dateTime", ">=", startWindow)
                .where("dateTime", "<=", endWindow)
                .get();

            // Filter out events where reminder has already been sent
            const eventsToRemind = eventsSnapshot.docs.filter(doc => !doc.data().reminderSent);

            if (eventsToRemind.length === 0) {
                console.log("No events found requiring reminders.");
                return;
            }

            console.log(`Found ${eventsToRemind.length} events to remind.`);

            const batch = db.batch();
            let batchCount = 0;

            for (const eventDoc of eventsToRemind) {
                const eventData = eventDoc.data();
                const participantIds = eventData.participantIds as string[];

                if (!participantIds || participantIds.length === 0) {
                    // Mark as sent anyway so we don't keep checking empty events
                    batch.update(eventDoc.ref, { reminderSent: true });
                    batchCount++;
                    continue;
                }

                // Fetch user tokens
                // Note: Firestore 'in' query supports max 10 values.
                // Since MAX_PARTICIPANTS is 6, we are safe.
                const userDocs = await db.collection("users")
                    .where(admin.firestore.FieldPath.documentId(), "in", participantIds)
                    .get();

                const tokens: string[] = [];
                userDocs.forEach(userDoc => {
                    const userData = userDoc.data();
                    if (userData.fcmToken) {
                        tokens.push(userData.fcmToken);
                    }
                });

                if (tokens.length > 0) {
                    // Format time for display (Taiwan Time UTC+8)
                    const eventDate = (eventData.dateTime as admin.firestore.Timestamp).toDate();
                    const timeString = new Intl.DateTimeFormat("zh-TW", {
                        hour: "2-digit",
                        minute: "2-digit",
                        hour12: false,
                        timeZone: "Asia/Taipei"
                    }).format(eventDate);

                    const message = {
                        notification: {
                            title: "📅 活動提醒",
                            body: `您的晚餐活動將於明天 ${timeString} 在 ${eventData.city} 舉行，別忘記準時出席喔！`,
                        },
                        tokens: tokens,
                        data: {
                            type: "event_reminder",
                            eventId: eventDoc.id,
                            click_action: "FLUTTER_NOTIFICATION_CLICK"
                        }
                    };

                    const response = await admin.messaging().sendEachForMulticast(message);
                    console.log(`Sent reminders for event ${eventDoc.id}: ${response.successCount} success, ${response.failureCount} failure.`);
                }

                // Update event to mark reminder as sent
                batch.update(eventDoc.ref, { reminderSent: true });
                batchCount++;
            }

            // Commit updates
            if (batchCount > 0) {
                await batch.commit();
                console.log(`Updated ${batchCount} events as reminded.`);
            }

        } catch (error) {
            console.error("Error in sendEventReminders:", error);
            throw error; // Re-throw to ensure Cloud Functions logs it as failure
        }
    });
