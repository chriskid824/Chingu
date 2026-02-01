import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { eventReminderTest, getNotificationCopy, NotificationCopyVariant } from "./notification_content";

// Ensure admin is initialized (idempotent check)
if (!admin.apps.length) {
    admin.initializeApp();
}

/**
 * Assigns a variant for A/B testing based on a deterministic hash of user ID and test ID.
 */
function assignVariant(userId: string, testId: string, variants: NotificationCopyVariant[]): string {
    let hash = 0;
    const str = userId + testId;
    for (let i = 0; i < str.length; i++) {
        hash = ((hash << 5) - hash) + str.charCodeAt(i);
        hash |= 0; // Convert to 32bit integer
    }
    const index = Math.abs(hash) % variants.length;
    return variants[index].variantId;
}

/**
 * Helper function to chunk array into smaller arrays
 */
function chunkArray<T>(array: T[], size: number): T[][] {
    const chunked: T[][] = [];
    for (let i = 0; i < array.length; i += size) {
        chunked.push(array.slice(i, i + size));
    }
    return chunked;
}

/**
 * Scheduled function to send event reminders 24 hours and 2 hours before the event.
 * Runs every 60 minutes.
 */
export const sendEventReminders = functions.pubsub.schedule("every 60 minutes").onRun(async (context) => {
    const db = admin.firestore();
    const now = new Date();

    // Calculate time windows
    // 24h reminder: Event is roughly 24h from now.
    // We check [now + 23h, now + 25h] to be safe, relying on is24hReminderSent to prevent duplicates.
    const start24 = new Date(now.getTime() + 23 * 60 * 60 * 1000);
    const end24 = new Date(now.getTime() + 25 * 60 * 60 * 1000);

    // 2h reminder: Event is roughly 2h from now.
    // We check [now + 1h, now + 3h].
    const start2 = new Date(now.getTime() + 1 * 60 * 60 * 1000);
    const end2 = new Date(now.getTime() + 3 * 60 * 60 * 1000);

    try {
        // --- 1. Process 24h Reminders ---
        const snapshot24 = await db.collection("dinner_events")
            .where("status", "==", "confirmed")
            .where("is24hReminderSent", "==", false)
            .where("dateTime", ">=", start24)
            .where("dateTime", "<=", end24)
            .get();

        console.log(`Found ${snapshot24.size} events for 24h reminder.`);
        await processReminders(db, snapshot24.docs, "24h");

        // --- 2. Process 2h Reminders ---
        const snapshot2 = await db.collection("dinner_events")
            .where("status", "==", "confirmed")
            .where("is2hReminderSent", "==", false)
            .where("dateTime", ">=", start2)
            .where("dateTime", "<=", end2)
            .get();

        console.log(`Found ${snapshot2.size} events for 2h reminder.`);
        await processReminders(db, snapshot2.docs, "2h");

    } catch (error) {
        console.error("Error in sendEventReminders:", error);
    }
});

async function processReminders(
    db: admin.firestore.Firestore,
    eventDocs: admin.firestore.QueryDocumentSnapshot[],
    type: "24h" | "2h"
) {
    for (const doc of eventDocs) {
        const eventData = doc.data();
        const participantIds: string[] = eventData.participantIds || [];

        if (participantIds.length === 0) continue;

        // Fetch users to get FCM tokens and preferences
        // Note: Firestore 'in' query supports max 10 items.
        // We chunk participantIds to handle cases with > 10 participants.
        const chunks = chunkArray(participantIds, 10);
        const userDocs: admin.firestore.QueryDocumentSnapshot[] = [];

        for (const chunk of chunks) {
            try {
                 const usersSnapshot = await db.collection("users")
                    .where(admin.firestore.FieldPath.documentId(), "in", chunk)
                    .get();
                 userDocs.push(...usersSnapshot.docs);
            } catch (e) {
                console.error(`Error fetching users chunk for event ${doc.id}:`, e);
            }
        }

        const updates: Promise<any>[] = [];

        for (const userDoc of userDocs) {
            const userData = userDoc.data();
            const fcmToken = userData.fcmToken;

            // Check preferences (default to true if missing)
            // Structure: userData.notificationPreferences.eventReminder
            const prefs = userData.notificationPreferences || {};
            const isEnabled = prefs.eventReminder !== false; // Default true

            if (fcmToken && isEnabled) {
                // Determine A/B variant
                const variantId = assignVariant(userDoc.id, eventReminderTest.testId, eventReminderTest.variants);

                const timeLeft = type === "24h" ? "24 小時" : "2 小時";
                const eventName = "晚餐活動";
                // eventData.dateTime is a Timestamp
                const eventDate = eventData.dateTime.toDate();
                const timeString = eventDate.toLocaleString('zh-TW', { hour: '2-digit', minute: '2-digit', hour12: false });

                const copy = getNotificationCopy(eventReminderTest.testId, variantId, {
                    eventName: eventName,
                    time: timeString,
                    timeLeft: timeLeft
                });

                const message = {
                    notification: {
                        title: copy.title,
                        body: copy.body,
                    },
                    token: fcmToken,
                    data: {
                        type: "event_reminder",
                        eventId: doc.id,
                        click_action: "FLUTTER_NOTIFICATION_CLICK",
                    }
                };

                updates.push(admin.messaging().send(message).catch(e => {
                    console.error(`Failed to send FCM to ${userDoc.id}:`, e);
                }));
            }
        }

        await Promise.all(updates);

        // Update event status
        const updateField = type === "24h" ? { is24hReminderSent: true } : { is2hReminderSent: true };
        await doc.ref.update(updateField);
    }
}
