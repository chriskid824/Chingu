import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Prevent duplicate initialization
if (!admin.apps.length) {
    admin.initializeApp();
}

/**
 * Scheduled function to send event reminders
 * Runs every hour to check for events happening in 24 hours or 2 hours
 */
export const sendEventReminders = functions.pubsub.schedule("0 * * * *")
    .timeZone("Asia/Taipei")
    .onRun(async (context) => {
        const db = admin.firestore();
        const now = new Date();

        console.log("Running sendEventReminders at:", now.toISOString());

        // ---------------------------------------------------------
        // 1. Check for 24-hour reminders (24h to 25h from now)
        // ---------------------------------------------------------
        const start24h = new Date(now.getTime() + 24 * 60 * 60 * 1000);
        const end24h = new Date(now.getTime() + 25 * 60 * 60 * 1000);

        const events24hSnapshot = await db.collection("dinner_events")
            .where("status", "==", "confirmed")
            .where("dateTime", ">=", start24h)
            .where("dateTime", "<", end24h)
            .get();

        const events24h = events24hSnapshot.docs.filter(doc => !doc.data().reminder24hSent);
        console.log(`Found ${events24h.length} events for 24h reminders`);

        for (const eventDoc of events24h) {
            await sendReminderForEvent(
                db,
                eventDoc,
                "晚餐提醒",
                "您的晚餐活動將在明天舉行，請準時出席！",
                "reminder24hSent"
            );
        }

        // ---------------------------------------------------------
        // 2. Check for 2-hour reminders (2h to 3h from now)
        // ---------------------------------------------------------
        const start2h = new Date(now.getTime() + 2 * 60 * 60 * 1000);
        const end2h = new Date(now.getTime() + 3 * 60 * 60 * 1000);

        const events2hSnapshot = await db.collection("dinner_events")
            .where("status", "==", "confirmed")
            .where("dateTime", ">=", start2h)
            .where("dateTime", "<", end2h)
            .get();

        const events2h = events2hSnapshot.docs.filter(doc => !doc.data().reminder2hSent);
        console.log(`Found ${events2h.length} events for 2h reminders`);

        for (const eventDoc of events2h) {
            await sendReminderForEvent(
                db,
                eventDoc,
                "晚餐提醒",
                "您的晚餐活動將在2小時後開始，別遲到喔！",
                "reminder2hSent"
            );
        }
    });

/**
 * Helper function to send reminders for a specific event
 */
async function sendReminderForEvent(
    db: admin.firestore.Firestore,
    eventDoc: admin.firestore.QueryDocumentSnapshot,
    title: string,
    body: string,
    flagField: string
) {
    try {
        const eventData = eventDoc.data();
        const eventId = eventDoc.id;
        const participantStatus = eventData.participantStatus || {};

        // Find confirmed participants
        const confirmedUserIds: string[] = [];
        for (const [uid, status] of Object.entries(participantStatus)) {
            if (status === "confirmed") {
                confirmedUserIds.push(uid);
            }
        }

        if (confirmedUserIds.length === 0) {
            console.log(`No confirmed participants for event ${eventId}`);
            // Still mark as sent so we don't retry endlessly?
            // Yes, likely nobody to remind.
            await eventDoc.ref.update({ [flagField]: true });
            return;
        }

        // Fetch tokens
        // Note: Firestore 'in' query supports up to 10 items.
        // Since max participants is 6, we can do a single query.
        const usersSnapshot = await db.collection("users")
            .where(admin.firestore.FieldPath.documentId(), "in", confirmedUserIds)
            .get();

        const tokens: string[] = [];
        usersSnapshot.docs.forEach(userDoc => {
            const userData = userDoc.data();
            if (userData.fcmToken) {
                tokens.push(userData.fcmToken);
            }
        });

        if (tokens.length > 0) {
            const message: admin.messaging.MulticastMessage = {
                notification: {
                    title: title,
                    body: body,
                },
                data: {
                    actionType: "view_event",
                    actionData: eventId,
                },
                tokens: tokens,
            };

            const response = await admin.messaging().sendEachForMulticast(message);
            console.log(`Sent reminders for event ${eventId}: ${response.successCount} success, ${response.failureCount} failed`);
        } else {
            console.log(`No tokens found for event ${eventId}`);
        }

        // Update the flag
        await eventDoc.ref.update({
            [flagField]: true,
            // Optional: also track when it was sent
            [`${flagField}At`]: admin.firestore.FieldValue.serverTimestamp()
        });
    } catch (error) {
        console.error(`Failed to process reminder for event ${eventDoc.id}:`, error);
    }
}
