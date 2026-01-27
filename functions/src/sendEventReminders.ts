import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Initialize admin if not already initialized
if (admin.apps.length === 0) {
    admin.initializeApp();
}

interface DinnerEvent {
    id: string;
    dateTime: admin.firestore.Timestamp;
    status: string;
    participantIds: string[];
    is24hReminderSent?: boolean;
    is2hReminderSent?: boolean;
    restaurantName?: string;
    restaurantAddress?: string;
}

/**
 * Scheduled Cloud Function to send event reminders
 * Runs every 15 minutes
 * Checks for events 24 hours and 2 hours before start time
 */
export const sendEventReminders = functions.pubsub.schedule("every 15 minutes").onRun(async (context) => {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();
    const nowMillis = now.toMillis();

    // 1. Calculate time windows
    // 24h window: [now + 23.5h, now + 24.5h]
    // 2h window: [now + 1.5h, now + 2.5h]
    const start24h = admin.firestore.Timestamp.fromMillis(nowMillis + (23.5 * 60 * 60 * 1000));
    const end24h = admin.firestore.Timestamp.fromMillis(nowMillis + (24.5 * 60 * 60 * 1000));

    const start2h = admin.firestore.Timestamp.fromMillis(nowMillis + (1.5 * 60 * 60 * 1000));
    const end2h = admin.firestore.Timestamp.fromMillis(nowMillis + (2.5 * 60 * 60 * 1000));

    const eventsRef = db.collection("dinner_events");

    // 2. Query for events in the time windows (confirmed only)
    // We filter is24hReminderSent/is2hReminderSent in memory to handle missing fields (backward compatibility)
    // and to avoid needing composite indexes immediately.

    const snapshot24h = await eventsRef
        .where("status", "==", "confirmed")
        .where("dateTime", ">=", start24h)
        .where("dateTime", "<=", end24h)
        .get();

    const snapshot2h = await eventsRef
        .where("status", "==", "confirmed")
        .where("dateTime", ">=", start2h)
        .where("dateTime", "<=", end2h)
        .get();

    console.log(`Found ${snapshot24h.size} potential 24h events and ${snapshot2h.size} potential 2h events.`);

    // Helper function to process and send reminders
    const processReminders = async (docs: admin.firestore.QueryDocumentSnapshot[], type: "24h" | "2h") => {
        let sentCount = 0;

        for (const doc of docs) {
            const data = doc.data() as DinnerEvent;
            const eventId = doc.id;

            // Check if reminder already sent
            if (type === "24h" && data.is24hReminderSent) continue;
            if (type === "2h" && data.is2hReminderSent) continue;

            const participantIds = data.participantIds || [];
            if (participantIds.length === 0) {
                 // Mark as handled even if no participants
                 await doc.ref.update(type === "24h" ? { is24hReminderSent: true } : { is2hReminderSent: true });
                 continue;
            }

            // Fetch user tokens
            // Note: Firestore 'in' query supports up to 30 items.
            // Dinner events have max 6 participants, so this is safe.
            const usersSnap = await db.collection("users")
                .where(admin.firestore.FieldPath.documentId(), "in", participantIds)
                .get();

            const tokens: string[] = [];
            usersSnap.forEach((userDoc) => {
                const userData = userDoc.data();
                if (userData.fcmToken) {
                    tokens.push(userData.fcmToken);
                }
            });

            if (tokens.length > 0) {
                const title = type === "24h"
                    ? "活動提醒：您的晚餐就在明天！"
                    : "活動提醒：晚餐即將在 2 小時後開始";

                const body = type === "24h"
                    ? `別忘了明天的聚餐${data.restaurantName ? ` @ ${data.restaurantName}` : ""}，點擊查看詳情。`
                    : `準備好出發了嗎？${data.restaurantName ? `前往 ${data.restaurantName}` : "點擊查看餐廳位置"}。`;

                const message: admin.messaging.MulticastMessage = {
                    notification: {
                        title,
                        body,
                    },
                    data: {
                        actionType: "view_event",
                        actionData: eventId,
                        eventId: eventId,
                        click_action: "FLUTTER_NOTIFICATION_CLICK",
                    },
                    tokens: tokens,
                };

                try {
                    const response = await admin.messaging().sendEachForMulticast(message);
                    if (response.failureCount > 0) {
                        console.warn(`Failed to send some ${type} reminders for event ${eventId}`);
                    }
                    sentCount++;
                } catch (e) {
                    console.error(`Error sending multicast for event ${eventId}:`, e);
                }
            }

            // Update event to mark reminder as sent
            await doc.ref.update(type === "24h" ? { is24hReminderSent: true } : { is2hReminderSent: true });
        }
        return sentCount;
    };

    const sent24h = await processReminders(snapshot24h.docs, "24h");
    const sent2h = await processReminders(snapshot2h.docs, "2h");

    console.log(`Sent ${sent24h} 24h-reminders and ${sent2h} 2h-reminders.`);
});
