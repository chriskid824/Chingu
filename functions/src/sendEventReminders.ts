import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { getNotificationCopy } from "./notification_content";

// Ensure admin is initialized
if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Scheduled function to send event reminders 24 hours before the event.
 * Runs every 30 minutes.
 *
 * Logic:
 * 1. Checks for events starting between 24h and 24.5h from now.
 * 2. Filters out cancelled events.
 * 3. Sends push notifications to all participants.
 */
export const sendEventReminders = functions.pubsub
    .schedule("every 30 minutes")
    .onRun(async (context) => {
        const now = admin.firestore.Timestamp.now();
        const nowMillis = now.toMillis();

        // Target window: 24 hours from now
        const twentyFourHours = 24 * 60 * 60 * 1000;
        // Window size matches the schedule frequency (30 mins)
        const windowSize = 30 * 60 * 1000;

        const startWindow = admin.firestore.Timestamp.fromMillis(nowMillis + twentyFourHours);
        const endWindow = admin.firestore.Timestamp.fromMillis(nowMillis + twentyFourHours + windowSize);

        console.log(`Checking for events between ${startWindow.toDate().toISOString()} and ${endWindow.toDate().toISOString()}`);

        try {
            const eventsSnapshot = await admin.firestore()
                .collection("dinner_events")
                .where("dateTime", ">=", startWindow)
                .where("dateTime", "<", endWindow)
                .where("status", "!=", "cancelled")
                .get();

            if (eventsSnapshot.empty) {
                console.log("No events found for reminder.");
                return null;
            }

            const sendPromises = eventsSnapshot.docs.map(async (doc) => {
                const eventData = doc.data();
                const participantIds = eventData.participantIds as string[];

                if (!participantIds || participantIds.length === 0) {
                    return;
                }

                // Fetch users to get FCM tokens
                // Firestore 'in' query supports up to 10 values.
                // Participants are max 6, so this is safe.
                const usersSnapshot = await admin.firestore()
                    .collection("users")
                    .where(admin.firestore.FieldPath.documentId(), "in", participantIds)
                    .get();

                const tokens: string[] = [];
                usersSnapshot.forEach((userDoc) => {
                    const userData = userDoc.data();
                    if (userData.fcmToken) {
                        tokens.push(userData.fcmToken);
                    }
                });

                if (tokens.length === 0) {
                    console.log(`No tokens found for event ${doc.id}`);
                    return;
                }

                // Format time for display (assuming events are mostly local/Taipei time for now,
                // but server might be UTC. We'll format to generic time string or assume client handles localization?
                // Actually, the message body is constructed here.
                // Let's use a simple format like HH:mm)
                const eventDate = (eventData.dateTime as admin.firestore.Timestamp).toDate();
                // Adjust to Taipei time (UTC+8) roughly for display if server is UTC
                // But simplified: just get HH:mm
                const timeString = eventDate.toLocaleTimeString("zh-TW", {
                    hour: '2-digit',
                    minute:'2-digit',
                    hour12: false,
                    timeZone: 'Asia/Taipei'
                });

                // Prepare notification content
                const { title, body } = getNotificationCopy(
                    "event_reminder_copy_v1",
                    "control",
                    {
                        eventName: "晚餐聚會", // Or `${eventData.city}晚餐`
                        time: `明天 ${timeString}`,
                        timeLeft: "24小時"
                    }
                );

                const message = {
                    notification: {
                        title,
                        body,
                    },
                    data: {
                        actionType: "view_event",
                        actionData: doc.id,
                        eventId: doc.id
                    },
                    tokens: tokens,
                };

                const response = await admin.messaging().sendEachForMulticast(message);
                console.log(`Sent reminders for event ${doc.id}: ${response.successCount} success, ${response.failureCount} failure`);
            });

            await Promise.all(sendPromises);
            return null;

        } catch (error) {
            console.error("Error sending event reminders:", error);
            return null;
        }
    });
