import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { getNotificationCopy, eventReminderTest } from "./notification_content";

// Ensure admin is initialized
if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Scheduled function to send reminders 24 hours before the event.
 * Runs every 60 minutes.
 */
export const sendEventReminders = functions.pubsub.schedule("every 60 minutes").onRun(async (context) => {
    const db = admin.firestore();
    const now = new Date();

    // Target time is 24 hours from now
    // We look for events happening around now + 24h
    const targetTime = new Date(now.getTime() + 24 * 60 * 60 * 1000);

    // Define a window of +/- 30 minutes to catch events
    // Since we run every 60 minutes, a 60-minute window (30 before, 30 after) ensures coverage
    // provided we mark them as sent.
    const startTime = new Date(targetTime.getTime() - 30 * 60 * 1000);
    const endTime = new Date(targetTime.getTime() + 30 * 60 * 1000);

    console.log(`Checking for events between ${startTime.toISOString()} and ${endTime.toISOString()}`);

    try {
        const eventsSnapshot = await db.collection("dinner_events")
            .where("dateTime", ">=", startTime)
            .where("dateTime", "<=", endTime)
            .get();

        if (eventsSnapshot.empty) {
            console.log("No upcoming events found in the target window.");
            return null;
        }

        let batch = db.batch();
        let notificationCount = 0;
        let processedEventsCount = 0;
        let operationCount = 0;

        for (const doc of eventsSnapshot.docs) {
            const eventData = doc.data();

            // Skip if reminder already sent to avoid duplicate notifications
            if (eventData.reminderSent === true) {
                continue;
            }

            const eventId = doc.id;
            const participantStatus = eventData.participantStatus || {};
            const confirmedUserIds: string[] = [];

            // Get confirmed participants
            for (const [userId, status] of Object.entries(participantStatus)) {
                if (status === 'confirmed') {
                    confirmedUserIds.push(userId);
                }
            }

            // Even if no confirmed participants, we should mark as sent so we don't process it again
            if (confirmedUserIds.length === 0) {
                batch.update(doc.ref, { reminderSent: true });
                operationCount++;
                if (operationCount >= 400) {
                    await batch.commit();
                    batch = db.batch();
                    operationCount = 0;
                }
                continue;
            }

            // Fetch user tokens
            // Firestore 'in' query supports up to 10 items. Since MAX_PARTICIPANTS is 6, this is safe.
            const usersSnapshot = await db.collection("users")
                .where(admin.firestore.FieldPath.documentId(), "in", confirmedUserIds)
                .get();

            const tokens: string[] = [];
            usersSnapshot.forEach(userDoc => {
                const userData = userDoc.data();
                if (userData.fcmToken) {
                    tokens.push(userData.fcmToken);
                }
            });

            if (tokens.length > 0) {
                // Prepare notification content
                const eventDate = (eventData.dateTime as admin.firestore.Timestamp).toDate();
                const timeString = eventDate.toLocaleTimeString('zh-TW', {
                    hour: '2-digit',
                    minute: '2-digit',
                    hour12: false,
                    timeZone: 'Asia/Taipei'
                });

                const eventName = eventData.restaurantName || `${eventData.city}晚餐聚會`;

                // Use default variant 'control' for simplicity.
                // Ideally we would fetch user's assigned variant from Firestore.
                const { title, body } = getNotificationCopy(
                    eventReminderTest.testId,
                    "control",
                    {
                        eventName: eventName,
                        time: timeString,
                        timeLeft: "24小時"
                    }
                );

                const message = {
                    notification: { title, body },
                    data: {
                        type: "event_reminder",
                        eventId: eventId,
                        click_action: "FLUTTER_NOTIFICATION_CLICK"
                    },
                    tokens: tokens
                };

                const response = await admin.messaging().sendEachForMulticast(message);
                console.log(`Sent reminders for event ${eventId}: ${response.successCount} success, ${response.failureCount} failed.`);
                notificationCount += response.successCount;
            }

            // Mark reminder as sent
            batch.update(doc.ref, { reminderSent: true });
            processedEventsCount++;
            operationCount++;

            if (operationCount >= 400) {
                await batch.commit();
                batch = db.batch();
                operationCount = 0;
            }
        }

        if (operationCount > 0) {
            await batch.commit();
        }

        console.log(`Processed ${processedEventsCount} events. Sent ${notificationCount} notifications.`);
        return null;

    } catch (error) {
        console.error("Error sending event reminders:", error);
        return null;
    }
});
