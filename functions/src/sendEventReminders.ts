import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { eventReminderTest, getNotificationCopy } from "./notification_content";

if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Scheduled function to send event reminders 24 hours and 2 hours before the event.
 * Runs every hour.
 */
export const sendEventReminders = functions.pubsub.schedule("0 * * * *").onRun(async (context) => {
    const db = admin.firestore();
    const now = new Date();

    // Calculate time windows
    // 24 hours from now (looking for events starting between 24h and 25h from now)
    const start24h = new Date(now.getTime() + 24 * 60 * 60 * 1000);
    const end24h = new Date(now.getTime() + 25 * 60 * 60 * 1000);

    // 2 hours from now (looking for events starting between 2h and 3h from now)
    const start2h = new Date(now.getTime() + 2 * 60 * 60 * 1000);
    const end2h = new Date(now.getTime() + 3 * 60 * 60 * 1000);

    try {
        await Promise.all([
            processReminders(db, start24h, end24h, "24h"),
            processReminders(db, start2h, end2h, "2h"),
        ]);
        console.log("Successfully processed event reminders.");
    } catch (error) {
        console.error("Error processing event reminders:", error);
    }
});

async function processReminders(
    db: admin.firestore.Firestore,
    start: Date,
    end: Date,
    type: "24h" | "2h"
) {
    // Query events in the time window
    const snapshot = await db.collection("dinner_events")
        .where("dateTime", ">=", start)
        .where("dateTime", "<", end)
        .get();

    if (snapshot.empty) return;

    let batch = db.batch();
    let batchCount = 0;

    for (const doc of snapshot.docs) {
        const event = doc.data();
        const remindersSent = event.remindersSent || [];

        // Check if reminder already sent
        if (remindersSent.includes(type)) continue;

        // Skip cancelled events
        if (event.status === "cancelled") continue;

        const participantIds: string[] = event.participantIds || [];
        if (participantIds.length === 0) continue;

        // Get user tokens
        // Note: 'in' query limited to 30. Dinner events have max 6 participants.
        const usersSnapshot = await db.collection("users")
            .where(admin.firestore.FieldPath.documentId(), "in", participantIds)
            .get();

        const tokens: string[] = [];
        usersSnapshot.docs.forEach((userDoc) => {
            const token = userDoc.data().fcmToken;
            if (token) tokens.push(token);
        });

        if (tokens.length > 0) {
            // Generate content
            const eventTime = (event.dateTime as admin.firestore.Timestamp).toDate();
            // Format time for Taiwan
            const timeString = eventTime.toLocaleString("zh-TW", {
                month: "short",
                day: "numeric",
                hour: "2-digit",
                minute: "2-digit",
                timeZone: "Asia/Taipei",
                hour12: false
            });

            // Get notification content using 'control' variant
            const content = getNotificationCopy(
                eventReminderTest.testId,
                "control",
                {
                    eventName: "晚餐聚會",
                    time: timeString,
                    timeLeft: type === "24h" ? "1天" : "2小時"
                }
            );

            const message = {
                notification: {
                    title: content.title,
                    body: content.body,
                },
                tokens: tokens,
            };

            // Send notification
            await admin.messaging().sendEachForMulticast(message);
            console.log(`Sent ${type} reminders for event ${doc.id} to ${tokens.length} users.`);
        }

        // Update event document to mark reminder as sent
        batch.update(doc.ref, {
            remindersSent: admin.firestore.FieldValue.arrayUnion(type)
        });
        batchCount++;

        if (batchCount >= 400) {
            await batch.commit();
            batch = db.batch();
            batchCount = 0;
        }
    }

    if (batchCount > 0) {
        await batch.commit();
    }
}
