import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {
    assignVariant,
    eventReminderTest,
    getNotificationCopy
} from "./notification_content";

/**
 * Scheduled function to send event reminders
 * Runs every hour to check for events starting in 24 hours and 2 hours
 */
export const sendEventReminders = functions.pubsub
    .schedule("every 1 hours")
    .onRun(async (context) => {
        if (!admin.apps.length) {
            admin.initializeApp();
        }

        const now = admin.firestore.Timestamp.now();
        const nowMillis = now.toMillis();

        // 24-hour reminder window (events starting between 24h and 25h from now)
        const start24h = admin.firestore.Timestamp.fromMillis(nowMillis + 24 * 60 * 60 * 1000);
        const end24h = admin.firestore.Timestamp.fromMillis(nowMillis + 25 * 60 * 60 * 1000);

        // 2-hour reminder window (events starting between 2h and 3h from now)
        const start2h = admin.firestore.Timestamp.fromMillis(nowMillis + 2 * 60 * 60 * 1000);
        const end2h = admin.firestore.Timestamp.fromMillis(nowMillis + 3 * 60 * 60 * 1000);

        console.log(`Checking for events between ${start24h.toDate().toISOString()} and ${end24h.toDate().toISOString()} (24h reminder)`);
        console.log(`Checking for events between ${start2h.toDate().toISOString()} and ${end2h.toDate().toISOString()} (2h reminder)`);

        try {
            await Promise.all([
                processReminders(start24h, end24h, "24小時"),
                processReminders(start2h, end2h, "2小時"),
            ]);
        } catch (error) {
            console.error("Error sending event reminders:", error);
        }
    });

async function processReminders(
    startTime: admin.firestore.Timestamp,
    endTime: admin.firestore.Timestamp,
    timeLeftLabel: string
) {
    const eventsSnapshot = await admin.firestore()
        .collection("dinner_events")
        .where("dateTime", ">=", startTime)
        .where("dateTime", "<", endTime)
        .where("status", "==", "confirmed")
        .get();

    if (eventsSnapshot.empty) {
        console.log(`No confirmed events found for ${timeLeftLabel} reminder.`);
        return;
    }

    console.log(`Found ${eventsSnapshot.size} events for ${timeLeftLabel} reminder.`);

    const promises = eventsSnapshot.docs.map(async (eventDoc) => {
        const eventData = eventDoc.data();
        const eventId = eventDoc.id;
        const participantIds = eventData.participantIds as string[] || [];
        const participantStatus = eventData.participantStatus as Record<string, string> || {};
        const eventName = eventData.restaurantName || "聚餐活動";
        const eventTime = (eventData.dateTime as admin.firestore.Timestamp).toDate();

        // Format time as HH:mm
        const timeString = eventTime.toLocaleTimeString("zh-TW", {
            hour: "2-digit",
            minute: "2-digit",
            hour12: false,
            timeZone: "Asia/Taipei"
        });

        // Filter confirmed participants
        const confirmedUserIds = participantIds.filter(uid => participantStatus[uid] === "confirmed");

        if (confirmedUserIds.length === 0) {
            return;
        }

        // Fetch users
        const userDocs = await Promise.all(
            confirmedUserIds.map(uid => admin.firestore().collection("users").doc(uid).get())
        );

        const notifications = [];

        for (const userDoc of userDocs) {
            if (!userDoc.exists) continue;

            const userData = userDoc.data();
            const fcmToken = userData?.fcmToken;
            const uid = userDoc.id;

            if (!fcmToken) {
                console.log(`User ${uid} has no FCM token. Skipping.`);
                continue;
            }

            // Assign variant
            const variantId = assignVariant(uid, eventReminderTest);

            // Get content
            const content = getNotificationCopy(
                eventReminderTest.testId,
                variantId,
                {
                    eventName: eventName,
                    time: timeString,
                    timeLeft: timeLeftLabel
                }
            );

            // Construct message
            const message = {
                notification: {
                    title: content.title,
                    body: content.body,
                },
                data: {
                    type: "event_reminder",
                    eventId: eventId,
                    click_action: "FLUTTER_NOTIFICATION_CLICK"
                },
                token: fcmToken
            };

            notifications.push(admin.messaging().send(message).then(async () => {
                // Log notification to Firestore
                 await admin.firestore()
                    .collection("users")
                    .doc(uid)
                    .collection("notifications")
                    .add({
                        type: "event_reminder",
                        title: content.title,
                        message: content.body,
                        actionType: "view_event",
                        actionData: eventId,
                        isRead: false,
                        createdAt: admin.firestore.FieldValue.serverTimestamp(),
                        variantId: variantId,
                        testId: eventReminderTest.testId
                    });
            }).catch(err => {
                console.error(`Failed to send reminder to ${uid} for event ${eventId}:`, err);
            }));
        }

        await Promise.all(notifications);
    });

    await Promise.all(promises);
}
