"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.sendDinnerEventReminders = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();
/**
 * Scheduled function to send dinner event reminders.
 * Runs every hour.
 * Checks for events starting in 24 hours (within a 1-hour window).
 */
exports.sendDinnerEventReminders = functions.pubsub
    .schedule("0 * * * *") // Run every hour
    .timeZone("Asia/Taipei") // Set timezone
    .onRun(async (context) => {
    const db = admin.firestore();
    const now = new Date();
    // Calculate the time range: 24 hours from now to 25 hours from now
    // We want to notify users roughly 24 hours before the event.
    // Since this runs every hour, we capture events in that hour slot.
    const startRange = new Date(now.getTime() + 24 * 60 * 60 * 1000); // Now + 24h
    const endRange = new Date(now.getTime() + 25 * 60 * 60 * 1000); // Now + 25h
    console.log(`Checking for events between ${startRange.toISOString()} and ${endRange.toISOString()}`);
    try {
        const eventsSnapshot = await db.collection("dinner_events")
            .where("dateTime", ">=", startRange)
            .where("dateTime", "<", endRange)
            .where("status", "==", "confirmed") // Only notify for confirmed events? Or pending too? Assuming confirmed or pending.
            // Actually, if it's 24h before, it might still be pending or confirmed.
            // Let's notify for both, or maybe just confirmed?
            // Usually 24h before, if it's pending, it might be cancelled soon if not full?
            // Let's check all non-cancelled events.
            // However, standard query limitations apply.
            // We can filter by status in code if needed, but 'dateTime' range is most important.
            .get();
        if (eventsSnapshot.empty) {
            console.log("No upcoming events found for this hour.");
            return null;
        }
        console.log(`Found ${eventsSnapshot.size} events.`);
        const sendPromises = [];
        for (const doc of eventsSnapshot.docs) {
            const eventData = doc.data();
            const eventId = doc.id;
            const participantReminders = eventData.participantReminders || {};
            // Skip cancelled events
            if (eventData.status === 'cancelled')
                continue;
            const participantIds = eventData.participantIds || [];
            for (const userId of participantIds) {
                // Check if reminder is enabled for this user (default to true if not present in map,
                // but if the map exists and user is missing, maybe default true?
                // Based on client code, we add to map on join. So it should be there.
                // If not in map, assume true (backward compatibility).
                // If in map and false, skip.
                let shouldRemind = true;
                if (participantReminders.hasOwnProperty(userId)) {
                    shouldRemind = participantReminders[userId];
                }
                if (!shouldRemind) {
                    console.log(`User ${userId} has disabled reminders for event ${eventId}.`);
                    continue;
                }
                // Fetch user's FCM token
                const userPromise = db.collection("users").doc(userId).get()
                    .then(async (userDoc) => {
                    if (!userDoc.exists)
                        return;
                    const userData = userDoc.data();
                    const fcmToken = userData === null || userData === void 0 ? void 0 : userData.fcmToken;
                    if (!fcmToken) {
                        console.log(`No FCM token for user ${userId}.`);
                        return;
                    }
                    // Construct notification payload
                    const message = {
                        token: fcmToken,
                        notification: {
                            title: "Dinner Event Reminder 🍽️",
                            body: "Your dinner event is coming up tomorrow! Get ready for a great meal.",
                        },
                        data: {
                            actionType: "view_event",
                            actionData: eventId,
                            click_action: "FLUTTER_NOTIFICATION_CLICK",
                        },
                    };
                    // Send notification
                    try {
                        await admin.messaging().send(message);
                        console.log(`Reminder sent to user ${userId} for event ${eventId}.`);
                    }
                    catch (error) {
                        console.error(`Error sending reminder to user ${userId}:`, error);
                        // Handle invalid tokens (optional: remove token from user)
                    }
                });
                sendPromises.push(userPromise);
            }
        }
        await Promise.all(sendPromises);
        console.log("All reminders processed.");
    }
    catch (error) {
        console.error("Error in sendDinnerEventReminders:", error);
    }
    return null;
});
//# sourceMappingURL=index.js.map