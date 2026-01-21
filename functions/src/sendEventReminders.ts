import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { eventReminderTest, getNotificationCopy, NotificationCopyTest } from "./notification_content";

// Ensure admin is initialized (check if already initialized to avoid errors)
if (admin.apps.length === 0) {
    admin.initializeApp();
}

const db = admin.firestore();

/**
 * Scheduled function to send event reminders
 * Runs every hour
 * Sends reminders 24 hours and 2 hours before the event
 */
export const sendEventReminders = functions.pubsub.schedule("every 1 hours").onRun(async (context) => {
    // Snap to start of the current hour to ensure contiguous windows
    // regardless of execution delay (e.g., if runs at 10:05, treat as 10:00)
    const now = new Date();
    now.setMinutes(0, 0, 0);
    const nowMillis = now.getTime();

    // Time windows
    // 24 hours ahead (check events starting between 24h and 25h from now)
    const start24h = admin.firestore.Timestamp.fromMillis(nowMillis + 24 * 60 * 60 * 1000);
    const end24h = admin.firestore.Timestamp.fromMillis(nowMillis + 25 * 60 * 60 * 1000);

    // 2 hours ahead (check events starting between 2h and 3h from now)
    const start2h = admin.firestore.Timestamp.fromMillis(nowMillis + 2 * 60 * 60 * 1000);
    const end2h = admin.firestore.Timestamp.fromMillis(nowMillis + 3 * 60 * 60 * 1000);

    try {
        await Promise.all([
            processReminders(start24h, end24h, "24h"),
            processReminders(start2h, end2h, "2h"),
        ]);

        console.log("Event reminders processing completed");
    } catch (error) {
        console.error("Error processing event reminders:", error);
    }
});

async function processReminders(
    start: admin.firestore.Timestamp,
    end: admin.firestore.Timestamp,
    type: "24h" | "2h"
) {
    const reminderField = type === "24h" ? "reminder24hSent" : "reminder2hSent";
    const timeLeftText = type === "24h" ? "24 hours" : "2 hours"; // Can be localized later

    // Query events in the time window
    const snapshot = await db.collection("dinner_events")
        .where("dateTime", ">=", start)
        .where("dateTime", "<", end)
        .where("status", "==", "confirmed") // Only remind for confirmed events
        .get();

    console.log(`Found ${snapshot.size} events for ${type} reminders`);

    for (const doc of snapshot.docs) {
        const eventData = doc.data();

        // Skip if reminder already sent
        if (eventData[reminderField] === true) {
            continue;
        }

        const eventId = doc.id;
        const participantIds: string[] = eventData.participantIds || [];
        const participantStatus: Record<string, string> = eventData.participantStatus || {};

        // Filter confirmed participants
        const targetUserIds = participantIds.filter(uid => participantStatus[uid] === "confirmed");

        if (targetUserIds.length === 0) {
             // Mark as sent even if no participants, to avoid re-processing
            await doc.ref.update({ [reminderField]: true });
            continue;
        }

        // Fetch user tokens
        // Firestore 'in' query supports max 10 values. If more participants, might need chunking.
        // But dinner events are fixed to 6 people. So it's safe.
        const usersSnapshot = await db.collection("users")
            .where(admin.firestore.FieldPath.documentId(), "in", targetUserIds)
            .get();

        const eventName = eventData.restaurantName || `Dinner in ${eventData.city || "town"}`;
        const eventTime = (eventData.dateTime as admin.firestore.Timestamp).toDate();
        // Format time nicely. For now, simple string.
        const timeString = eventTime.toLocaleTimeString("en-US", {
            hour: "2-digit",
            minute: "2-digit",
            hour12: false,
            timeZone: "Asia/Taipei"
        });

        for (const userDoc of usersSnapshot.docs) {
            const userData = userDoc.data();
            const fcmToken = userData.fcmToken;
            const userId = userDoc.id;

            if (!fcmToken) continue;

            // Determine A/B test variant
            const variant = getVariantForUser(userId, eventReminderTest);

            // Get notification copy
            const { title, body } = getNotificationCopy(
                eventReminderTest.testId,
                variant.variantId,
                {
                    eventName: eventName,
                    time: timeString,
                    timeLeft: timeLeftText,
                }
            );

            // Send message
            try {
                await admin.messaging().send({
                    token: fcmToken,
                    notification: {
                        title,
                        body,
                    },
                    data: {
                        type: "view_event",
                        eventId: eventId,
                        click_action: "FLUTTER_NOTIFICATION_CLICK",
                    },
                });
            } catch (e) {
                console.error(`Failed to send reminder to user ${userId} for event ${eventId}`, e);
            }
        }

        // Update event doc
        await doc.ref.update({ [reminderField]: true });
    }
}

function getVariantForUser(userId: string, test: NotificationCopyTest): any {
    if (!test || !test.variants || test.variants.length === 0) return null;

    // Simple deterministic hash
    let hash = 0;
    for (let i = 0; i < userId.length; i++) {
        const char = userId.charCodeAt(i);
        hash = ((hash << 5) - hash) + char;
        hash = hash & hash; // Convert to 32bit integer
    }

    const index = Math.abs(hash) % test.variants.length;
    return test.variants[index];
}
