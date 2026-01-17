import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { getNotificationCopy, eventReminderTest } from "./notification_content";

// Defensive initialization
if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Scheduled function to send event reminders 24 hours before the event.
 * Runs every hour.
 */
export const sendEventReminders = functions.pubsub.schedule('every 1 hours').onRun(async (context) => {
    const db = admin.firestore();
    const now = new Date();

    // Calculate the time window: 24 hours from now (inclusive) to 25 hours from now (exclusive)
    // We check events starting in this window.
    const startWindow = new Date(now.getTime() + 24 * 60 * 60 * 1000);
    const endWindow = new Date(now.getTime() + 25 * 60 * 60 * 1000);

    console.log(`Checking for events between ${startWindow.toISOString()} and ${endWindow.toISOString()}`);

    try {
        // Query events in the time window
        const eventsSnapshot = await db.collection('dinner_events')
            .where('dateTime', '>=', startWindow)
            .where('dateTime', '<', endWindow)
            .get();

        if (eventsSnapshot.empty) {
            console.log("No upcoming events found in this window.");
            return null;
        }

        const batchPromises: Promise<any>[] = [];

        for (const doc of eventsSnapshot.docs) {
            const eventData = doc.data();

            // Only remind for confirmed events
            // We filter in memory to avoid needing a composite index on status + dateTime
            if (eventData.status !== 'confirmed') {
                continue;
            }

            const participantIds: string[] = eventData.participantIds || [];
            if (participantIds.length === 0) continue;

            // Fetch users to get FCM tokens
            // Note: In a high-scale system, we might want to batch these reads or store tokens in event.
            // Firestore 'in' query supports up to 30 items.
            // Since DinnerEvent is capped at 6 participants, this is safe.
            const usersSnapshot = await db.collection('users')
                .where(admin.firestore.FieldPath.documentId(), 'in', participantIds)
                .get();

            const tokens: string[] = [];
            usersSnapshot.docs.forEach(userDoc => {
                const userData = userDoc.data();
                if (userData.fcmToken) {
                    tokens.push(userData.fcmToken);
                }
            });

            if (tokens.length === 0) continue;

            // Prepare notification content
            // We use 'control' variant as default since we don't fetch user variants here for simplicity
            // Format time for display (Taiwan time)
            const eventDate = (eventData.dateTime as admin.firestore.Timestamp).toDate();
            const timeString = eventDate.toLocaleTimeString('zh-TW', {
                hour: '2-digit',
                minute: '2-digit',
                timeZone: 'Asia/Taipei',
                hour12: false
            });

            const { title, body } = getNotificationCopy(
                eventReminderTest.testId,
                eventReminderTest.defaultVariantId, // 'control'
                {
                    eventName: `晚餐聚會 (${eventData.district})`, // e.g. "晚餐聚會 (Xinyi)"
                    time: timeString,
                    timeLeft: '24小時' // Not used in 'control' variant but provided for completeness
                }
            );

            // Send multicast message
            const message = {
                notification: {
                    title,
                    body,
                },
                tokens: tokens,
                data: {
                    type: 'event_reminder',
                    eventId: doc.id,
                    click_action: 'FLUTTER_NOTIFICATION_CLICK' // Standard for Flutter
                }
            };

            const sendPromise = admin.messaging().sendEachForMulticast(message)
                .then(response => {
                    console.log(`Sent reminders for event ${doc.id}: ${response.successCount} success, ${response.failureCount} failed.`);
                    if (response.failureCount > 0) {
                        response.responses.forEach((resp, idx) => {
                            if (!resp.success) {
                                console.error(`Failed to send to token ${tokens[idx]}:`, resp.error);
                            }
                        });
                    }
                })
                .catch(error => {
                    console.error(`Error sending reminders for event ${doc.id}:`, error);
                });

            batchPromises.push(sendPromise);
        }

        await Promise.all(batchPromises);
        return null;

    } catch (error) {
        console.error("Error in sendEventReminders:", error);
        return null;
    }
});
