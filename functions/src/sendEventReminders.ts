import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Cloud Scheduler job to send dinner event reminders 24 hours in advance.
 * Runs every hour.
 */
export const sendEventReminders = functions.pubsub.schedule("every 1 hours").onRun(async (context) => {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();

    // Calculate 24h window
    const startWindow = new Date(now.toMillis() + 24 * 60 * 60 * 1000);
    const endWindow = new Date(now.toMillis() + 25 * 60 * 60 * 1000);

    const startTimestamp = admin.firestore.Timestamp.fromDate(startWindow);
    const endTimestamp = admin.firestore.Timestamp.fromDate(endWindow);

    console.log(`Checking for events between ${startWindow.toISOString()} and ${endWindow.toISOString()}`);

    try {
        const eventsSnapshot = await db.collection("dinner_events")
            .where("dateTime", ">=", startTimestamp)
            .where("dateTime", "<", endTimestamp)
            .where("status", "in", ["pending", "confirmed"])
            .get();

        if (eventsSnapshot.empty) {
            console.log("No events found for reminders.");
            return null;
        }

        console.log(`Found ${eventsSnapshot.size} events to remind.`);

        let batch = db.batch();
        let batchCount = 0;
        const commits: Promise<FirebaseFirestore.WriteResult[]>[] = [];
        let notificationCount = 0;

        for (const doc of eventsSnapshot.docs) {
            const eventData = doc.data();

            if (eventData.remindersSent) {
                continue;
            }

            const participantIds: string[] = eventData.participantIds || [];
            // Note: Firestore 'in' query supports up to 30 items.
            // Our app limits event participants to 6 (MAX_PARTICIPANTS), so this is safe.
            if (participantIds.length === 0) continue;

            const usersSnapshot = await db.collection("users")
                .where(admin.firestore.FieldPath.documentId(), "in", participantIds)
                .get();

            const tokens: string[] = [];
            usersSnapshot.forEach((userDoc) => {
                const userData = userDoc.data();
                if (userData.fcmToken) {
                    tokens.push(userData.fcmToken);
                }
            });

            if (tokens.length > 0) {
                const date = (eventData.dateTime as admin.firestore.Timestamp).toDate();

                // Format time for Taipei (UTC+8)
                const options: Intl.DateTimeFormatOptions = {
                    timeZone: "Asia/Taipei",
                    hour: "2-digit",
                    minute: "2-digit",
                    hour12: false,
                };
                const timeString = new Intl.DateTimeFormat("en-US", options).format(date);

                const message = {
                    notification: {
                        title: "晚餐活動提醒",
                        body: `別忘了明天 ${timeString} 在 ${eventData.city} ${eventData.district} 的聚餐！`,
                    },
                    data: {
                        actionType: "view_event",
                        actionData: doc.id,
                        eventId: doc.id,
                    },
                    tokens: tokens,
                };

                const response = await admin.messaging().sendEachForMulticast(message);
                console.log(`Sent reminder for event ${doc.id}: ${response.successCount} success, ${response.failureCount} failure.`);
                notificationCount += response.successCount;
            }

            batch.update(doc.ref, { remindersSent: true });
            batchCount++;

            // Commit batch if limit reached (limit is 500)
            if (batchCount >= 500) {
                commits.push(batch.commit());
                batch = db.batch();
                batchCount = 0;
            }
        }

        if (batchCount > 0) {
            commits.push(batch.commit());
        }

        await Promise.all(commits);
        console.log(`Reminders process completed. Total sent: ${notificationCount}`);

    } catch (error) {
        console.error("Error sending event reminders:", error);
    }

    return null;
});
