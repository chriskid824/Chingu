import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import dayjs from "dayjs";

if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Scheduled function to send event reminders
 * Runs every hour to check for events occurring in ~24h and ~2h
 */
export const sendEventReminders = functions.pubsub.schedule("0 * * * *").onRun(async (context) => {
    const db = admin.firestore();
    const now = dayjs();

    console.log("Running event reminder check at:", now.toISOString());

    // 24h Reminders: Look for events 23.5 - 24.5 hours from now
    const start24 = now.add(23.5, "hour").toDate();
    const end24 = now.add(24.5, "hour").toDate();

    // 2h Reminders: Look for events 1.5 - 2.5 hours from now
    const start2 = now.add(1.5, "hour").toDate();
    const end2 = now.add(2.5, "hour").toDate();

    try {
        // Execute queries
        const snapshot24 = await db.collection("dinner_events")
            .where("status", "==", "confirmed")
            .where("dateTime", ">=", start24)
            .where("dateTime", "<=", end24)
            .get();

        const snapshot2 = await db.collection("dinner_events")
            .where("status", "==", "confirmed")
            .where("dateTime", ">=", start2)
            .where("dateTime", "<=", end2)
            .get();

        console.log(`Found ${snapshot24.size} events for 24h reminder and ${snapshot2.size} events for 2h reminder.`);

        // Process
        await processReminders(db, snapshot24, "24h");
        await processReminders(db, snapshot2, "2h");

        return null;
    } catch (error) {
        console.error("Error in sendEventReminders:", error);
        return null;
    }
});

async function processReminders(
    db: admin.firestore.Firestore,
    snapshot: admin.firestore.QuerySnapshot,
    type: "24h" | "2h"
) {
    for (const doc of snapshot.docs) {
        const data = doc.data();

        // Skip if reminder already sent
        if (type === "24h" && data.is24hReminderSent) continue;
        if (type === "2h" && data.is2hReminderSent) continue;

        const participantIds = data.participantIds || [];
        if (participantIds.length === 0) continue;

        try {
            // Fetch tokens
            // Firestore 'in' query supports up to 10 items. Participants are max 6.
            const usersSnap = await db.collection("users")
                .where(admin.firestore.FieldPath.documentId(), "in", participantIds)
                .get();

            const tokens = usersSnap.docs
                .map((d) => d.data().fcmToken)
                .filter((t) => t); // Filter out null/undefined

            if (tokens.length > 0) {
                // Convert to UTC+8 (Taiwan Time) for display
                const eventTime = dayjs(data.dateTime.toDate()).add(8, "hour");
                const timeString = eventTime.format("HH:mm");

                let title = "";
                let body = "";

                if (type === "24h") {
                    title = "活動提醒：明天見！";
                    body = `您的聚餐活動將在明天 ${timeString} 開始，別忘了準時出席喔！`;
                } else {
                    title = "活動提醒：活動即將開始！";
                    body = `您的聚餐活動將在 2 小時後 (${timeString}) 開始，請準備出發！`;
                }

                const message = {
                    tokens: tokens,
                    notification: {
                        title: title,
                        body: body,
                    },
                    data: {
                        type: "event_reminder",
                        eventId: doc.id,
                        click_action: "FLUTTER_NOTIFICATION_CLICK",
                    },
                };

                const response = await admin.messaging().sendEachForMulticast(message);
                console.log(`Sent ${type} reminders for event ${doc.id}: ${response.successCount} success, ${response.failureCount} failed.`);
            }

            // Update flag
            await doc.ref.update({
                [type === "24h" ? "is24hReminderSent" : "is2hReminderSent"]: true,
            });

        } catch (err) {
            console.error(`Error processing event ${doc.id} for ${type} reminder:`, err);
        }
    }
}
