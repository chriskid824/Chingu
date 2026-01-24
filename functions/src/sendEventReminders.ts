import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import { getNotificationCopy } from "./notification_content";

// Ensure admin is initialized
if (admin.apps.length === 0) {
    admin.initializeApp();
}

const db = admin.firestore();

/**
 * Scheduled function to send event reminders
 * Runs every hour
 */
export const sendEventReminders = onSchedule("every 1 hours", async (event) => {
    const now = new Date();

    console.log(`Running event reminders at ${now.toISOString()}`);

    // 24 hours reminder
    await processReminders(now, 24, "reminder24hSent");

    // 2 hours reminder
    await processReminders(now, 2, "reminder2hSent");
});

async function processReminders(now: Date, hoursBefore: number, flagField: string) {
    // Target time is 'hoursBefore' from now
    const targetTime = new Date(now.getTime() + hoursBefore * 60 * 60 * 1000);

    // We look for events that are starting within a window around the target time.
    // Since we run every hour, a +/- 30 minute window creates a continuous coverage
    // (e.g. 11:30-12:30, then 12:30-13:30) and centers the reminder time.
    const startWindow = new Date(targetTime.getTime() - 30 * 60 * 1000); // target - 30m
    const endWindow = new Date(targetTime.getTime() + 30 * 60 * 1000);   // target + 30m

    try {
        const snapshot = await db.collection("dinner_events")
            .where("dateTime", ">=", startWindow)
            .where("dateTime", "<=", endWindow)
            .get();

        console.log(`Found ${snapshot.size} events potentially needing ${hoursBefore}h reminder`);

        for (const doc of snapshot.docs) {
            const data = doc.data();

            // Check flag to avoid duplicates
            if (data[flagField] === true) continue;

            // Check status (only remind for pending or confirmed events)
            if (data.status !== "pending" && data.status !== "confirmed") continue;

            // Send reminder
            await sendReminder(doc, hoursBefore, flagField);
        }
    } catch (error) {
        console.error(`Error processing ${hoursBefore}h reminders:`, error);
    }
}

async function sendReminder(eventDoc: FirebaseFirestore.QueryDocumentSnapshot, hoursBefore: number, flagField: string) {
    const eventId = eventDoc.id;
    const data = eventDoc.data();
    const participantIds = data.participantIds || [];

    if (participantIds.length === 0) return;

    try {
        // Fetch users to get FCM tokens
        // Firestore 'in' query supports up to 10 values
        // Dinner events have max 6 participants, so this is safe
        const usersSnap = await db.collection("users")
            .where(admin.firestore.FieldPath.documentId(), "in", participantIds)
            .get();

        const tokens: string[] = [];
        usersSnap.forEach(userDoc => {
            const userData = userDoc.data();
            if (userData.fcmToken) {
                tokens.push(userData.fcmToken);
            }
        });

        if (tokens.length === 0) {
            // No tokens found, but mark as sent so we don't keep checking
            await eventDoc.ref.update({ [flagField]: true });
            return;
        }

        // Prepare notification content
        const eventName = data.restaurantName || `Dinner in ${data.district}`;

        // Format time to Taipei time (UTC+8)
        const eventDate = data.dateTime.toDate();
        const options: Intl.DateTimeFormatOptions = {
            hour: '2-digit',
            minute: '2-digit',
            timeZone: 'Asia/Taipei',
            hour12: false
        };
        const timeStr = eventDate.toLocaleString('zh-TW', options);

        // Localized time left string
        const timeLeftZh = hoursBefore === 24 ? "1天" : "2小時";

        const content = getNotificationCopy('event_reminder_copy_v1', 'control', {
            eventName: eventName,
            time: timeStr,
            timeLeft: timeLeftZh
        });

        const message = {
            notification: {
                title: content.title,
                body: content.body,
            },
            data: {
                type: "event_reminder",
                eventId: eventId,
                deeplink: `app://event/${eventId}`
            },
            tokens: tokens
        };

        const response = await admin.messaging().sendEachForMulticast(message);
        console.log(`Sent ${hoursBefore}h reminders for event ${eventId}: ${response.successCount} success, ${response.failureCount} failed`);

        // Mark as sent
        await eventDoc.ref.update({ [flagField]: true });

    } catch (error) {
        console.error(`Error sending reminder for event ${eventId}:`, error);
    }
}
