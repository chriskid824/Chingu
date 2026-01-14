const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendEventReminders = functions.pubsub.schedule("every 60 minutes").onRun(async (context) => {
  const now = new Date();
  const db = admin.firestore();
  const fcm = admin.messaging();

  // Calculate time windows
  // Widen the window to 90 minutes to handle scheduler drift (e.g. 24h to 25.5h)
  const window24hStart = new Date(now.getTime() + 24 * 60 * 60 * 1000); // Now + 24h
  const window24hEnd = new Date(window24hStart.getTime() + 90 * 60 * 1000); // Now + 25.5h

  const window2hStart = new Date(now.getTime() + 2 * 60 * 60 * 1000); // Now + 2h
  const window2hEnd = new Date(window2hStart.getTime() + 90 * 60 * 1000); // Now + 3.5h

  const eventsRef = db.collection("dinner_events");

  // Helper function to chunk array
  const chunkArray = (array, size) => {
    const chunked = [];
    for (let i = 0; i < array.length; i += size) {
      chunked.push(array.slice(i, i + size));
    }
    return chunked;
  };

  // Helper function to process events
  const processEvents = async (querySnapshot, reminderType) => {
    const promises = [];
    querySnapshot.forEach((doc) => {
      const eventData = doc.data();
      const remindersSent = eventData.remindersSent || {};

      // Check if reminder already sent
      if (remindersSent[reminderType]) {
        return;
      }

      // Check status (only notify for confirmed or pending events that are not cancelled)
      if (eventData.status === "cancelled" || eventData.status === "completed") {
        return;
      }

      const participantIds = eventData.participantIds || [];
      if (participantIds.length === 0) {
        return;
      }

      promises.push(
          (async () => {
            // Fetch users to get FCM tokens in chunks of 10
            const participantChunks = chunkArray(participantIds, 10);
            const tokens = [];

            for (const chunk of participantChunks) {
              const userSnapshots = await db.collection("users")
                  .where(admin.firestore.FieldPath.documentId(), "in", chunk)
                  .get();

              userSnapshots.forEach((userDoc) => {
                const userData = userDoc.data();
                // Check notification preferences
                if (userData.fcmToken && userData.eventReminderNotificationsEnabled !== false) {
                  tokens.push(userData.fcmToken);
                }
              });
            }

            if (tokens.length > 0) {
              const title = "晚餐活動提醒";
              let body = "";
              if (reminderType === "24h") {
                body = "您的聚餐將在 24 小時後開始，請準時出席！";
              } else {
                body = "您的聚餐將在 2 小時後開始，別忘記囉！";
              }

              const message = {
                notification: {
                  title: title,
                  body: body,
                },
                data: {
                  actionType: "view_event",
                  actionData: doc.id,
                  type: "event", // fallback
                  id: doc.id, // fallback
                },
                tokens: tokens,
              };

              // Send multicast message
              try {
                const response = await fcm.sendMulticast(message);
                console.log(`Sent ${reminderType} reminders for event ${doc.id}: ${response.successCount} successes, ${response.failureCount} failures.`);
              } catch (e) {
                console.error(`Error sending ${reminderType} reminders for event ${doc.id}:`, e);
              }
            }

            // Update event document to mark reminder as sent
            // We use update with dot notation for nested field
            await doc.ref.update({
              [`remindersSent.${reminderType}`]: true,
            });
          })(),
      );
    });
    await Promise.all(promises);
  };

  // Query for 24h reminders
  const query24h = eventsRef
      .where("dateTime", ">=", window24hStart)
      .where("dateTime", "<", window24hEnd);

  const snapshot24h = await query24h.get();
  await processEvents(snapshot24h, "24h");

  // Query for 2h reminders
  const query2h = eventsRef
      .where("dateTime", ">=", window2hStart)
      .where("dateTime", "<", window2hEnd);

  const snapshot2h = await query2h.get();
  await processEvents(snapshot2h, "2h");

  console.log("Event reminders check completed.");
});
