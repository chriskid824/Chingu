import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (!admin.apps.length) {
    admin.initializeApp();
}

/**
 * Cloud Function to send event reminders
 * Runs every hour to check for upcoming events
 */
export const sendEventReminders = functions.pubsub
    .schedule("every 1 hours")
    .onRun(async (context) => {
        const db = admin.firestore();
        const now = Date.now();

        // Time constants
        const HOUR_MS = 60 * 60 * 1000;

        // 24h Reminder Window: Events starting in [23h, 25h] from now
        // We look for events that start roughly 24 hours from now.
        // Since we run every hour, a window of 2 hours (23-25) ensures we catch it
        // even if the cron triggers slightly off or we want to be safe.
        // We rely on the `is24hReminderSent` flag to avoid duplicates.
        const start24h = new Date(now + 23 * HOUR_MS);
        const end24h = new Date(now + 25 * HOUR_MS);

        // 2h Reminder Window: Events starting in [1h, 3h] from now
        const start2h = new Date(now + 1 * HOUR_MS);
        const end2h = new Date(now + 3 * HOUR_MS);

        try {
            // 1. Process 24h Reminders
            const events24hSnapshot = await db.collection("dinner_events")
                .where("status", "==", "confirmed")
                .where("dateTime", ">=", admin.firestore.Timestamp.fromDate(start24h))
                .where("dateTime", "<=", admin.firestore.Timestamp.fromDate(end24h))
                .get();

            const events24h = events24hSnapshot.docs.filter(doc => !doc.data().is24hReminderSent);

            console.log(`Found ${events24h.length} events for 24h reminder.`);

            for (const doc of events24h) {
                await sendReminderForEvent(db, doc, "24h");
            }

            // 2. Process 2h Reminders
            const events2hSnapshot = await db.collection("dinner_events")
                .where("status", "==", "confirmed")
                .where("dateTime", ">=", admin.firestore.Timestamp.fromDate(start2h))
                .where("dateTime", "<=", admin.firestore.Timestamp.fromDate(end2h))
                .get();

            const events2h = events2hSnapshot.docs.filter(doc => !doc.data().is2hReminderSent);

            console.log(`Found ${events2h.length} events for 2h reminder.`);

            for (const doc of events2h) {
                await sendReminderForEvent(db, doc, "2h");
            }

        } catch (error) {
            console.error("Error in sendEventReminders:", error);
        }
    });

/**
 * Helper function to send reminder for a specific event
 */
async function sendReminderForEvent(
    db: admin.firestore.Firestore,
    eventDoc: admin.firestore.QueryDocumentSnapshot,
    type: "24h" | "2h"
) {
    const eventData = eventDoc.data();
    const participantIds = eventData.participantIds as string[];

    if (!participantIds || participantIds.length === 0) return;

    // Fetch users to get tokens
    // Using getAll for efficiency since IDs are known
    const userRefs = participantIds.map(id => db.collection("users").doc(id));
    const userSnapshots = await db.getAll(...userRefs);

    const tokens: string[] = [];
    userSnapshots.forEach(userDoc => {
        if (userDoc.exists) {
            const userData = userDoc.data();
            if (userData && userData.fcmToken) {
                tokens.push(userData.fcmToken);
            }
        }
    });

    if (tokens.length === 0) {
        console.log(`No tokens found for event ${eventDoc.id}`);
        // Still mark as sent so we don't retry forever?
        // Or maybe we want to retry if tokens appear?
        // Probably safe to mark as sent to avoid spamming logs or logic.
        // But if no one has tokens, maybe we shouldn't mark it?
        // Let's mark it to avoid processing again.
    } else {
        const title = "活動提醒";
        const body = type === "24h"
            ? `您的聚餐活動將在 24 小時後開始！記得準時出席喔。`
            : `您的聚餐活動即將在 2 小時後開始！別忘了出門喔。`;

        const message = {
            notification: {
                title: title,
                body: body,
            },
            data: {
                actionType: "view_event",
                actionData: eventDoc.id, // Assuming 'view_event' takes event ID
                click_action: "FLUTTER_NOTIFICATION_CLICK",
            },
            tokens: tokens,
        };

        try {
            const response = await admin.messaging().sendEachForMulticast(message);
            console.log(`Sent ${type} reminder for event ${eventDoc.id}. Success: ${response.successCount}, Failure: ${response.failureCount}`);
        } catch (error) {
            console.error(`Error sending FCM for event ${eventDoc.id}:`, error);
        }
    }

    // Update event to mark reminder as sent
    // Use a variable for the field name
    const updateData = type === "24h"
        ? { is24hReminderSent: true }
        : { is2hReminderSent: true };

    await eventDoc.ref.update(updateData);
}
