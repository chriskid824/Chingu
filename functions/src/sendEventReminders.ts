import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { eventReminderTest, getNotificationCopy } from "./notification_content";

if (admin.apps.length === 0) {
    admin.initializeApp();
}

const db = admin.firestore();

export const sendEventReminders = functions.pubsub.schedule("every 1 hours").onRun(async (context) => {
    const now = new Date();

    // Windows:
    // 2h reminder: events starting in [now + 1.5h, now + 2.5h]
    // 24h reminder: events starting in [now + 23.5h, now + 24.5h]
    // This ensures we catch events roughly 2h or 24h before, with 1h schedule frequency.

    const start2h = new Date(now.getTime() + 1.5 * 60 * 60 * 1000);
    const end2h = new Date(now.getTime() + 2.5 * 60 * 60 * 1000);

    const start24h = new Date(now.getTime() + 23.5 * 60 * 60 * 1000);
    const end24h = new Date(now.getTime() + 24.5 * 60 * 60 * 1000);

    // Helper to process reminders
    const processReminders = async (type: "2h" | "24h", start: Date, end: Date) => {
        const eventsSnapshot = await db.collection("dinner_events")
            .where("dateTime", ">=", start)
            .where("dateTime", "<=", end)
            .where("status", "==", "confirmed")
            .get();

        const fieldToCheck = type === "2h" ? "reminder2hSent" : "reminder24hSent";

        for (const doc of eventsSnapshot.docs) {
            const eventData = doc.data();
            if (eventData[fieldToCheck]) {
                continue;
            }

            const participantIds: string[] = eventData.participantIds || [];
            if (participantIds.length === 0) continue;

            // Fetch users
            const usersSnapshot = await db.collection("users")
                .where(admin.firestore.FieldPath.documentId(), "in", participantIds)
                .get();

            const messages: admin.messaging.Message[] = [];
            const batch = db.batch();
            let batchCount = 0;

            for (const userDoc of usersSnapshot.docs) {
                const userData = userDoc.data();
                const fcmToken = userData.fcmToken;
                if (!fcmToken) continue;

                // A/B Test Variant Logic - Simplified (Read only)
                let variantId = eventReminderTest.defaultVariantId;
                const variantRef = userDoc.ref.collection("ab_test_variants").doc(eventReminderTest.testId);
                const variantDoc = await variantRef.get();

                if (variantDoc.exists) {
                    variantId = variantDoc.data()?.variantId || variantId;
                }
                // Fallback to default if not assigned, do not auto-assign to reduce writes/complexity

                // Prepare Content
                const params = {
                    eventName: eventData.restaurantName || "晚餐活動",
                    time: type === "24h" ? "明天" : "2小時後",
                    timeLeft: type === "24h" ? "24小時" : "2小時",
                };

                const { title, body } = getNotificationCopy(eventReminderTest.testId, variantId, params);

                messages.push({
                    token: fcmToken,
                    notification: {
                        title,
                        body,
                    },
                    data: {
                        type: "event_reminder",
                        eventId: doc.id,
                        click_action: "FLUTTER_NOTIFICATION_CLICK",
                    },
                });
            }

            // Send Messages
            if (messages.length > 0) {
                await admin.messaging().sendEach(messages);
                console.log(`Sent ${type} reminders for event ${doc.id} to ${messages.length} users.`);
            }

            // Mark event as reminded
            batch.update(doc.ref, { [fieldToCheck]: true });
            batchCount++;

            if (batchCount > 0) {
                await batch.commit();
            }
        }
    };

    await processReminders("2h", start2h, end2h);
    await processReminders("24h", start24h, end24h);
});
