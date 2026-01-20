import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as crypto from "crypto";
import { eventReminderTest, getNotificationCopy } from "./notification_content";

// Prevent multiple initializations
if (admin.apps.length === 0) {
    admin.initializeApp();
}

interface DinnerEvent {
    id: string;
    remindersSent?: { [key: string]: boolean };
    participantIds?: string[];
    dateTime?: admin.firestore.Timestamp;
    restaurantName?: string;
    [key: string]: any;
}

/**
 * Scheduled function to send event reminders
 * Runs every hour to check for events starting in 24h or 2h
 */
export const sendEventReminders = functions.pubsub.schedule("0 * * * *").onRun(async (context) => {
    const now = new Date();
    // Align to the start of the hour to ensure we cover the full hour window
    // even if the function execution is slightly delayed
    now.setMinutes(0, 0, 0);

    const db = admin.firestore();

    // We check for events in the next hour window relative to our target times
    // Target 1: 24 hours from now
    const target24hStart = new Date(now.getTime() + 24 * 60 * 60 * 1000);
    const target24hEnd = new Date(target24hStart.getTime() + 60 * 60 * 1000);

    // Target 2: 2 hours from now
    const target2hStart = new Date(now.getTime() + 2 * 60 * 60 * 1000);
    const target2hEnd = new Date(target2hStart.getTime() + 60 * 60 * 1000);

    console.log(`Checking events for 24h reminder: ${target24hStart.toISOString()} - ${target24hEnd.toISOString()}`);
    console.log(`Checking events for 2h reminder: ${target2hStart.toISOString()} - ${target2hEnd.toISOString()}`);

    try {
        // Query for events
        const [events24h, events2h] = await Promise.all([
            getEventsInWindow(db, target24hStart, target24hEnd),
            getEventsInWindow(db, target2hStart, target2hEnd)
        ]);

        console.log(`Found ${events24h.length} events for 24h reminder`);
        console.log(`Found ${events2h.length} events for 2h reminder`);

        const notifications: Promise<any>[] = [];

        // Process 24h reminders
        for (const event of events24h) {
            if (event.remindersSent && event.remindersSent["24h"]) {
                console.log(`Skipping 24h reminder for event ${event.id}: already sent.`);
                continue;
            }
            notifications.push(
                processEventReminder(db, event, "24小時")
                    .then(() => markReminderSent(db, event.id, "24h"))
            );
        }

        // Process 2h reminders
        for (const event of events2h) {
            if (event.remindersSent && event.remindersSent["2h"]) {
                console.log(`Skipping 2h reminder for event ${event.id}: already sent.`);
                continue;
            }
            notifications.push(
                processEventReminder(db, event, "2小時")
                    .then(() => markReminderSent(db, event.id, "2h"))
            );
        }

        await Promise.all(notifications);
        console.log("Finished sending reminders");

    } catch (error) {
        console.error("Error in sendEventReminders:", error);
    }
});

async function getEventsInWindow(db: admin.firestore.Firestore, start: Date, end: Date): Promise<DinnerEvent[]> {
    const snapshot = await db.collection("dinner_events")
        .where("status", "==", "confirmed")
        .where("dateTime", ">=", start)
        .where("dateTime", "<", end)
        .get();

    return snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
    })) as DinnerEvent[];
}

async function processEventReminder(db: admin.firestore.Firestore, event: DinnerEvent, timeLeft: string) {
    if (!event.participantIds || event.participantIds.length === 0) {
        return;
    }

    const eventName = event.restaurantName || "晚餐活動";
    const eventTime = (event.dateTime as admin.firestore.Timestamp).toDate();

    // Format time for Taiwan
    const timeString = new Intl.DateTimeFormat('zh-TW', {
        timeZone: 'Asia/Taipei',
        hour: 'numeric',
        minute: 'numeric',
        hour12: false
    }).format(eventTime);

    // Fetch users
    // Firestore 'in' query supports max 10 values. We might need to chunk.
    const userIds = event.participantIds as string[];
    const chunks = [];
    for (let i = 0; i < userIds.length; i += 10) {
        chunks.push(userIds.slice(i, i + 10));
    }

    const users: any[] = [];
    for (const chunk of chunks) {
        const snap = await db.collection("users")
            .where(admin.firestore.FieldPath.documentId(), "in", chunk)
            .get();
        snap.docs.forEach(doc => users.push({ id: doc.id, ...doc.data() }));
    }

    // Group users by variant to optimize sending
    // However, A/B logic assigns variant per user.
    // If multiple users map to the same variant, we can batch them.

    const messagesByVariant: Record<string, string[]> = {}; // variantId -> tokens[]

    for (const user of users) {
        if (!user.fcmToken) continue;

        const variantId = getVariantForUser(user.id);
        if (!messagesByVariant[variantId]) {
            messagesByVariant[variantId] = [];
        }
        messagesByVariant[variantId].push(user.fcmToken);
    }

    // Send messages for each variant group
    for (const [variantId, tokens] of Object.entries(messagesByVariant)) {
        const copy = getNotificationCopy(eventReminderTest.testId, variantId, {
            eventName: eventName,
            time: timeString,
            timeLeft: timeLeft
        });

        if (tokens.length > 0) {
            const message = {
                notification: {
                    title: copy.title,
                    body: copy.body,
                },
                tokens: tokens,
                data: {
                    type: "event_reminder",
                    eventId: event.id
                }
            };

            try {
                const response = await admin.messaging().sendEachForMulticast(message);
                console.log(`Sent ${response.successCount} reminders (variant: ${variantId}) for event ${event.id}`);
            } catch (err) {
                console.error(`Failed to send reminders (variant: ${variantId}) for event ${event.id}`, err);
            }
        }
    }
}

function getVariantForUser(userId: string): string {
    const hash = crypto.createHash("md5").update(userId).digest("hex");
    const val = parseInt(hash.substring(0, 8), 16);
    const variants = eventReminderTest.variants;
    const index = val % variants.length;
    return variants[index].variantId;
}

async function markReminderSent(db: admin.firestore.Firestore, eventId: string, type: "24h" | "2h") {
    try {
        await db.collection("dinner_events").doc(eventId).set({
            remindersSent: {
                [type]: true
            }
        }, { merge: true });
        console.log(`Marked ${type} reminder as sent for event ${eventId}`);
    } catch (error) {
        console.error(`Failed to mark ${type} reminder as sent for event ${eventId}`, error);
    }
}
