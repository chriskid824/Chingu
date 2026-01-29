import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { getNotificationCopy } from "./notification_content";

if (!admin.apps.length) {
    admin.initializeApp();
}

/**
 * Scheduled function to send event reminders 24 hours before the event.
 * Runs every hour.
 */
export const sendEventReminders = functions.pubsub
    .schedule("every 1 hours")
    .onRun(async (context) => {
        const now = admin.firestore.Timestamp.now();
        const nowMillis = now.toMillis();

        // Target window: Events starting between 24h and 25h from now
        const startWindow = nowMillis + (24 * 60 * 60 * 1000); // +24h
        const endWindow = nowMillis + (25 * 60 * 60 * 1000);   // +25h

        const startTimestamp = admin.firestore.Timestamp.fromMillis(startWindow);
        const endTimestamp = admin.firestore.Timestamp.fromMillis(endWindow);

        console.log(`Checking for events between ${startTimestamp.toDate().toISOString()} and ${endTimestamp.toDate().toISOString()}`);

        try {
            const eventsSnapshot = await admin.firestore()
                .collection("dinner_events")
                .where("dateTime", ">=", startTimestamp)
                .where("dateTime", "<", endTimestamp)
                .get();

            if (eventsSnapshot.empty) {
                console.log("No upcoming events found in the target window.");
                return null;
            }

            console.log(`Found ${eventsSnapshot.size} events.`);

            const batch = admin.firestore().batch();
            let updatesCount = 0;

            for (const doc of eventsSnapshot.docs) {
                const eventData = doc.data();

                // Skip if reminder already sent
                if (eventData.reminderSentAt) {
                    console.log(`Event ${doc.id}: Reminder already sent at ${eventData.reminderSentAt.toDate().toISOString()}`);
                    continue;
                }

                // Skip cancelled events
                if (eventData.status === "cancelled") {
                    continue;
                }

                const participantIds: string[] = eventData.participantIds || [];
                if (participantIds.length === 0) {
                    continue;
                }

                // Fetch participants to get tokens
                // Firestore 'in' query supports up to 10
                // We'll fetch individually or in batches if needed.
                // Since max participants is 6, we can fetch all at once with 'in' if supported,
                // or just loop since it's small.

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
                    console.log(`Event ${doc.id}: No valid tokens found for participants.`);
                    // Still mark as sent to avoid retrying indefinitely?
                    // Or maybe not? If we mark it, we won't retry.
                    // Given it's a time window, retrying in next hour won't help as window shifts.
                    // But if we fail to send, maybe we should log error.
                    // Let's mark as sent to be safe.
                } else {
                    // Prepare notification content
                    // Defaulting to control variant for now. In future, fetch user variant.
                    // But users might have different variants.
                    // Multicast sends same message to all tokens.
                    // We'll pick 'control' for simplicity.
                    const eventDate = eventData.dateTime instanceof admin.firestore.Timestamp
                        ? eventData.dateTime.toDate()
                        : new Date(eventData.dateTime);

                    const timeString = eventDate.toLocaleTimeString("zh-TW", {
                        hour: '2-digit',
                        minute: '2-digit',
                        hour12: false
                    });

                    const notificationContent = getNotificationCopy(
                        "event_reminder_copy_v1",
                        "control",
                        {
                            eventName: "晚餐聚會", // Or custom name if available
                            time: timeString
                        }
                    );

                    const message = {
                        notification: {
                            title: notificationContent.title,
                            body: notificationContent.body,
                        },
                        tokens: tokens,
                        data: {
                            type: "event_reminder",
                            eventId: doc.id,
                            click_action: "FLUTTER_NOTIFICATION_CLICK",
                        }
                    };

                    const response = await admin.messaging().sendEachForMulticast(message);
                    console.log(`Event ${doc.id}: Sent reminders. Success: ${response.successCount}, Failure: ${response.failureCount}`);
                }

                // Mark reminder as sent
                batch.update(doc.ref, {
                    reminderSentAt: admin.firestore.FieldValue.serverTimestamp()
                });
                updatesCount++;
            }

            if (updatesCount > 0) {
                await batch.commit();
                console.log(`Updated ${updatesCount} events with reminderSentAt.`);
            }

        } catch (error) {
            console.error("Error in sendEventReminders:", error);
        }

        return null;
    });
