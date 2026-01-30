import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { getNotificationCopy, eventReminderTest } from "./notification_content";

// Ensure app is initialized
if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Scheduled function to send event reminders 24 hours before the event.
 * Runs every hour.
 */
export const sendEventReminders = functions.pubsub.schedule("every 60 minutes").onRun(async (context) => {
    const db = admin.firestore();
    const now = new Date();

    // Calculate window: events starting between 23 hours and 25 hours from now
    // We want to catch events happening roughly 24h from now.
    // Running hourly means we check:
    // T: checks [T+23, T+25]
    // T+1: checks [T+24, T+26]
    // Overlap ensures we don't miss any, but we must check reminderSent24h flag.
    const startWindow = new Date(now.getTime() + 23 * 60 * 60 * 1000);
    const endWindow = new Date(now.getTime() + 25 * 60 * 60 * 1000);

    console.log(`Checking for events between ${startWindow.toISOString()} and ${endWindow.toISOString()}`);

    try {
        const eventsSnapshot = await db.collection("dinner_events")
            .where("dateTime", ">=", startWindow)
            .where("dateTime", "<=", endWindow)
            .get();

        const promises: Promise<any>[] = [];
        let count = 0;

        for (const doc of eventsSnapshot.docs) {
            const eventData = doc.data();

            // Skip if already sent or cancelled
            if (eventData.reminderSent24h === true) {
                continue;
            }

            if (eventData.status === 'cancelled') {
                continue;
            }

            const participantIds: string[] = eventData.participantIds || [];
            if (participantIds.length === 0) continue;

            count++;

            // Format time for local string (assuming Taiwan time for display, or simple string)
            // Since we run on server, localeString might be UTC.
            // Ideally we format based on user timezone or just generic time.
            // Using zh-TW and UTC+8
            const eventDate = (eventData.dateTime as admin.firestore.Timestamp).toDate();
            const timeString = eventDate.toLocaleTimeString('zh-TW', {
                timeZone: 'Asia/Taipei',
                hour: '2-digit',
                minute: '2-digit',
                hour12: false
            });

            // Fetch users for tokens
            const userDocs = await db.collection("users")
                .where(admin.firestore.FieldPath.documentId(), "in", participantIds)
                .get();

            // Send notification to each user
            for (const userDoc of userDocs.docs) {
                const userData = userDoc.data();
                const fcmToken = userData.fcmToken;

                if (!fcmToken) continue;

                // Simple consistent hash for A/B variant assignment
                const variants = eventReminderTest.variants;
                let hash = 0;
                const userId = userDoc.id;
                for (let i = 0; i < userId.length; i++) {
                    hash = ((hash << 5) - hash) + userId.charCodeAt(i);
                    hash |= 0;
                }
                const variantIndex = Math.abs(hash) % variants.length;
                const variantId = variants[variantIndex].variantId;

                const { title, body } = getNotificationCopy(
                    eventReminderTest.testId,
                    variantId,
                    {
                        eventName: "晚餐聚會",
                        time: timeString,
                        timeLeft: "24 小時"
                    }
                );

                const message = {
                    notification: {
                        title,
                        body,
                    },
                    token: fcmToken,
                    data: {
                        click_action: "FLUTTER_NOTIFICATION_CLICK",
                        type: "event_reminder",
                        eventId: doc.id
                    }
                };

                promises.push(admin.messaging().send(message)
                    .catch(err => console.error(`Failed to send reminder to ${userId}:`, err)));
            }

            // Update event to prevent resending
            promises.push(doc.ref.update({ reminderSent24h: true }));
        }

        await Promise.all(promises);
        console.log(`Sent reminders for ${count} events.`);

    } catch (error) {
        console.error("Error sending event reminders:", error);
    }
});
