import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Initialize admin app if not already initialized
if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Scheduled function to send event reminders
 * Runs every hour
 * - Sends 24h reminder (24h before event)
 * - Sends 2h reminder (2h before event)
 */
export const sendEventReminders = functions.pubsub.schedule("every 1 hours").onRun(async (context) => {
    const now = new Date();
    const db = admin.firestore();
    const messaging = admin.messaging();

    const tasks: Promise<any>[] = [];

    // --- 24 Hour Reminders ---
    // Look for events starting between 23.5 and 25 hours from now
    // And is24hReminderSent is false
    // Window: [now + 23.5h, now + 25h]
    const start24h = new Date(now.getTime() + (23.5 * 60 * 60 * 1000));
    const end24h = new Date(now.getTime() + (25 * 60 * 60 * 1000));

    const events24hQuery = db.collection("dinner_events")
        .where("status", "==", "confirmed")
        .where("is24hReminderSent", "==", false)
        .where("dateTime", ">=", start24h)
        .where("dateTime", "<=", end24h);

    tasks.push(processReminders(events24hQuery, "24h", db, messaging));

    // --- 2 Hour Reminders ---
    // Look for events starting between 1.5 and 3 hours from now
    // And is2hReminderSent is false
    // Window: [now + 1.5h, now + 3h]
    const start2h = new Date(now.getTime() + (1.5 * 60 * 60 * 1000));
    const end2h = new Date(now.getTime() + (3 * 60 * 60 * 1000));

    const events2hQuery = db.collection("dinner_events")
        .where("status", "==", "confirmed")
        .where("is2hReminderSent", "==", false)
        .where("dateTime", ">=", start2h)
        .where("dateTime", "<=", end2h);

    tasks.push(processReminders(events2hQuery, "2h", db, messaging));

    await Promise.all(tasks);
    console.log("Finished sending event reminders");
    return null;
});

async function processReminders(
    query: admin.firestore.Query,
    type: "24h" | "2h",
    db: admin.firestore.Firestore,
    messaging: admin.messaging.Messaging
) {
    const snapshot = await query.get();
    if (snapshot.empty) return;

    console.log(`Found ${snapshot.size} events for ${type} reminder`);

    for (const doc of snapshot.docs) {
        const eventData = doc.data();
        const participantIds = eventData.participantIds as string[];

        if (!participantIds || participantIds.length === 0) continue;

        // Get user tokens
        // Firestore 'in' query supports up to 10 values.
        // Dinner events have max 6 participants.
        let tokens: string[] = [];
        try {
            const usersSnapshot = await db.collection("users")
                .where(admin.firestore.FieldPath.documentId(), "in", participantIds)
                .get();

            usersSnapshot.forEach(userDoc => {
                const userData = userDoc.data();
                // Check if user has an FCM token and hasn't disabled dinner reminders
                if (userData.fcmToken && userData.notifyDinnerReminder !== false) {
                    tokens.push(userData.fcmToken);
                }
            });
        } catch (error) {
            console.error(`Error fetching users for event ${doc.id}:`, error);
            continue;
        }

        if (tokens.length > 0) {
            const title = type === "24h" ? "活動提醒" : "活動即將開始";
            const body = type === "24h"
                ? "您的聚餐活動將在24小時後開始，請準時出席！"
                : "您的聚餐活動將在2小時後開始，別忘記囉！";

            const message = {
                notification: {
                    title: title,
                    body: body,
                },
                data: {
                    type: "event_reminder",
                    eventId: doc.id,
                    click_action: "FLUTTER_NOTIFICATION_CLICK",
                },
                tokens: tokens,
            };

            try {
                const response = await messaging.sendEachForMulticast(message);
                console.log(`Sent ${type} reminder for event ${doc.id}: ${response.successCount} success, ${response.failureCount} failure`);

                if (response.failureCount > 0) {
                    response.responses.forEach((resp, idx) => {
                        if (!resp.success) {
                            console.error(`Error sending to token ${tokens[idx]}:`, resp.error);
                            // Optional: Remove invalid tokens if error code indicates so
                        }
                    });
                }
            } catch (e) {
                console.error(`Error sending ${type} reminder for event ${doc.id}:`, e);
            }
        } else {
             console.log(`No valid tokens found for event ${doc.id}`);
        }

        // Update event document regardless of whether emails were sent (to avoid retry loops if no tokens)
        // Or should we only update if at least one sent?
        // Better to update to avoid infinite processing if users just have no tokens.
        const updateData = type === "24h"
            ? { is24hReminderSent: true }
            : { is2hReminderSent: true };

        try {
            await doc.ref.update(updateData);
        } catch (e) {
            console.error(`Error updating event ${doc.id} status:`, e);
        }
    }
}
