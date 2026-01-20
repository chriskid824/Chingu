import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as crypto from "crypto";
import { eventReminderTest, getNotificationCopy } from "./notification_content";

// Ensure firebase-admin is initialized (it might be initialized in index.ts, but safe to do here or check)
if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Deterministically gets the variant for a user based on their ID and the test ID.
 */
function getVariantForUser(userId: string, testId: string, variants: { variantId: string }[]): string {
    const hash = crypto.createHash("md5").update(`${testId}:${userId}`).digest("hex");
    const index = parseInt(hash.substring(0, 8), 16) % variants.length;
    return variants[index].variantId;
}

/**
 * Scheduled function to send event reminders 24 hours before the event.
 * Runs every hour.
 */
export const sendEventReminders = functions.pubsub.schedule("every 60 minutes").onRun(async (context) => {
    // Get current time but align to the start of the hour to avoid gaps due to execution latency
    const now = new Date();
    const currentHour = new Date(now.getFullYear(), now.getMonth(), now.getDate(), now.getHours(), 0, 0);

    // Target window: [Current Hour + 24h, Current Hour + 25h)
    // Example: If running at 10:00:05, currentHour is 10:00:00.
    // We check for events scheduled between 10:00:00 tomorrow and 11:00:00 tomorrow.
    // The next run at 11:00:05 will check 11:00:00 to 12:00:00.
    const startMillis = currentHour.getTime() + 24 * 60 * 60 * 1000;
    const endMillis = startMillis + 60 * 60 * 1000;

    const startWindow = admin.firestore.Timestamp.fromMillis(startMillis);
    const endWindow = admin.firestore.Timestamp.fromMillis(endMillis);

    console.log(`Checking for events between ${startWindow.toDate().toISOString()} and ${endWindow.toDate().toISOString()}`);

    try {
        const eventsSnapshot = await admin.firestore()
            .collection("dinner_events")
            .where("dateTime", ">=", startWindow)
            .where("dateTime", "<", endWindow)
            // .where("status", "==", "confirmed") // Optional: only remind for confirmed events?
            // The prompt doesn't specify status, but reminding for 'pending' events is also fine to ensure they don't forget.
            // Usually reminders are for things that are happening. If status is cancelled, we shouldn't remind.
            // Let's filter out cancelled events in code or query.
            .get();

        if (eventsSnapshot.empty) {
            console.log("No events found in the target window.");
            return;
        }

        console.log(`Found ${eventsSnapshot.size} events to remind.`);

        const promises = eventsSnapshot.docs.map(async (doc) => {
            const eventData = doc.data();

            // Skip cancelled events
            if (eventData.status === "cancelled") {
                return;
            }

            const eventId = doc.id;
            const eventName = eventData.title || "晚餐聚會"; // Fallback title
            const eventTime = (eventData.dateTime as admin.firestore.Timestamp).toDate();
            const timeString = eventTime.toLocaleTimeString("zh-TW", {
                hour: "2-digit",
                minute: "2-digit",
                hour12: false,
                timeZone: "Asia/Taipei"
            });

            // Calculate "Time Left" for the dynamic copy
            const diffHours = Math.round((eventTime.getTime() - Date.now()) / (1000 * 60 * 60));
            const timeLeft = `${diffHours}小時`;

            const participantIds: string[] = eventData.participantIds || [];

            if (participantIds.length === 0) {
                return;
            }

            // Fetch users to get FCM tokens
            // Firestore 'in' query supports up to 10 items. participantIds max is 6, but we chunk to be safe.
            const chunkSize = 10;
            const chunks = [];
            for (let i = 0; i < participantIds.length; i += chunkSize) {
                chunks.push(participantIds.slice(i, i + chunkSize));
            }

            const notifications: Promise<any>[] = [];

            for (const chunk of chunks) {
                const usersSnapshot = await admin.firestore()
                    .collection("users")
                    .where(admin.firestore.FieldPath.documentId(), "in", chunk)
                    .get();

                usersSnapshot.docs.forEach((userDoc) => {
                const userData = userDoc.data();
                const fcmToken = userData.fcmToken;
                const userId = userDoc.id;

                if (!fcmToken) {
                    console.log(`User ${userId} has no FCM token.`);
                    return;
                }

                // Determine A/B test variant
                const variantId = getVariantForUser(userId, eventReminderTest.testId, eventReminderTest.variants);

                // Get copy
                const { title, body } = getNotificationCopy(eventReminderTest.testId, variantId, {
                    eventName: eventName,
                    time: timeString,
                    timeLeft: timeLeft,
                });

                const message = {
                    notification: {
                        title: title,
                        body: body,
                    },
                    data: {
                        type: "event_reminder",
                        eventId: eventId,
                        click_action: "FLUTTER_NOTIFICATION_CLICK",
                    },
                    token: fcmToken,
                };

                notifications.push(
                    admin.messaging().send(message)
                        .then(() => {
                            console.log(`Sent reminder to user ${userId} for event ${eventId}`);
                            // Optional: Log to notification_logs
                        })
                        .catch((error) => {
                            console.error(`Failed to send reminder to user ${userId}:`, error);
                            // Handle invalid token (e.g. remove it)
                            if (error.code === 'messaging/registration-token-not-registered') {
                                return userDoc.ref.update({ fcmToken: admin.firestore.FieldValue.delete() });
                            }
                            // Return something for TS consistency, though .catch returns Promise<void | WriteResult> which is fine
                            return null;
                        })
                );
            });
            }

            await Promise.all(notifications);
        });

        await Promise.all(promises);
        console.log("Finished sending event reminders.");

    } catch (error) {
        console.error("Error in sendEventReminders:", error);
    }
});
