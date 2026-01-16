import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
    admin.initializeApp();
}

const db = admin.firestore();

/**
 * Scheduled function to check for upcoming events and send reminders.
 * Runs every 60 minutes.
 */
export const checkEventReminders = functions.pubsub.schedule("every 60 minutes").onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();
    const nowMillis = now.toMillis();

    console.log(`Running checkEventReminders at ${now.toDate().toISOString()}`);

    // 24 Hours Logic
    // Target: Events starting between [now + 24h] and [now + 25h]
    const start24h = admin.firestore.Timestamp.fromMillis(nowMillis + (24 * 60 * 60 * 1000));
    const end24h = admin.firestore.Timestamp.fromMillis(nowMillis + (25 * 60 * 60 * 1000));

    await processReminders(start24h, end24h, "24h");

    // 2 Hours Logic
    // Target: Events starting between [now + 2h] and [now + 3h]
    const start2h = admin.firestore.Timestamp.fromMillis(nowMillis + (2 * 60 * 60 * 1000));
    const end2h = admin.firestore.Timestamp.fromMillis(nowMillis + (3 * 60 * 60 * 1000));

    await processReminders(start2h, end2h, "2h");
});

async function processReminders(start: admin.firestore.Timestamp, end: admin.firestore.Timestamp, type: "24h" | "2h") {
    const eventsRef = db.collection("dinner_events");
    const flagField = type === "24h" ? "reminder24hSent" : "reminder2hSent";

    try {
        const querySnapshot = await eventsRef
            .where("dateTime", ">=", start)
            .where("dateTime", "<", end)
            .where("status", "==", "confirmed")
            .get();

        if (querySnapshot.empty) {
            console.log(`No confirmed events found for ${type} reminder window.`);
            return;
        }

        const updates: Promise<any>[] = [];

        for (const doc of querySnapshot.docs) {
            const data = doc.data();

            // Check if already sent
            if (data[flagField] === true) {
                console.log(`Skipping event ${doc.id} for ${type} reminder, already sent.`);
                continue;
            }

            const participantIds: string[] = data.participantIds || [];
            if (participantIds.length === 0) continue;

            console.log(`Sending ${type} reminder for event ${doc.id} to ${participantIds.length} participants.`);

            // Send notifications
            await sendNotifications(participantIds, doc.id, data, type);

            // Mark as sent
            updates.push(doc.ref.update({ [flagField]: true }));
        }

        await Promise.all(updates);
    } catch (error) {
        console.error(`Error processing ${type} reminders:`, error);
    }
}

async function sendNotifications(userIds: string[], eventId: string, eventData: any, type: "24h" | "2h") {
    // 1. Get tokens
    // We can't use 'in' query for more than 10 items.
    // Chunk userIds.
    const chunks = [];
    for (let i = 0; i < userIds.length; i += 10) {
        chunks.push(userIds.slice(i, i + 10));
    }

    const tokens: string[] = [];

    for (const chunk of chunks) {
        try {
            const userSnapshots = await db.collection("users")
                .where(admin.firestore.FieldPath.documentId(), "in", chunk)
                .get();

            userSnapshots.docs.forEach(doc => {
                const token = doc.data().fcmToken;
                if (token) tokens.push(token);
            });
        } catch (e) {
            console.error("Error fetching user tokens:", e);
        }
    }

    if (tokens.length === 0) {
        console.log(`No tokens found for event ${eventId}`);
        return;
    }

    // 2. Construct Message
    const eventTime = (eventData.dateTime as admin.firestore.Timestamp).toDate();
    const timeString = eventTime.toLocaleString("zh-TW", {
        timeZone: "Asia/Taipei",
        hour: '2-digit',
        minute: '2-digit',
        month: 'numeric',
        day: 'numeric'
    });

    let title = "活動提醒";
    let body = "";

    if (type === "24h") {
        body = `您的聚餐活動將在明天 ${timeString} 舉行，請準時出席！`;
    } else {
        body = `您的聚餐活動即將在 ${timeString} 開始 (2小時後)，別忘囉！`;
    }

    // Multicast message limits to 500 tokens.
    // If we have > 500 participants (unlikely for dinner events of 6), we should chunk tokens.
    // Assuming max 6 participants, so no need to chunk tokens.

    const message = {
        notification: {
            title,
            body,
        },
        data: {
            type: "event_reminder",
            eventId: eventId,
            click_action: "FLUTTER_NOTIFICATION_CLICK"
        },
        tokens: tokens,
    };

    try {
        const response = await admin.messaging().sendEachForMulticast(message);
        console.log(`Sent ${type} reminders for event ${eventId}. Success: ${response.successCount}, Failure: ${response.failureCount}`);

        if (response.failureCount > 0) {
             response.responses.forEach((resp, idx) => {
                if (!resp.success) {
                    // console.error(`Error sending to token ${tokens[idx]}:`, resp.error);
                    // Optional: Remove invalid tokens
                }
            });
        }
    } catch (e) {
        console.error("Error sending multicast message:", e);
    }
}
