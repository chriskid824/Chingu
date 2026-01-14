const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

/**
 * 透過 Cloud Scheduler 每小時執行一次
 * 檢查是否有活動在 24 小時後開始，並發送提醒
 */
exports.sendEventReminders = functions.pubsub.schedule('every 1 hours').onRun(async (context) => {
    const db = admin.firestore();
    const messaging = admin.messaging();

    // 計算目標時間範圍 (24小時後)
    // 我們檢查未來 24 到 25 小時內的活動 (假設每小時跑一次)
    const now = new Date();
    const startRange = new Date(now.getTime() + 24 * 60 * 60 * 1000); // 24小時後
    const endRange = new Date(now.getTime() + 25 * 60 * 60 * 1000);   // 25小時後

    console.log(`Checking events between ${startRange.toISOString()} and ${endRange.toISOString()}`);

    try {
        const eventsSnapshot = await db.collection('dinner_events')
            .where('dateTime', '>=', startRange)
            .where('dateTime', '<', endRange)
            .where('status', 'in', ['confirmed', 'pending']) // 只提醒確認或待定活動
            .get();

        if (eventsSnapshot.empty) {
            console.log('No events found for reminder.');
            return null;
        }

        const promises = [];

        eventsSnapshot.forEach(doc => {
            const event = doc.data();
            const participantIds = event.participantIds || [];

            if (participantIds.length === 0) return;

            // 獲取所有參與者的 FCM Token
            const eventPromise = db.collection('users')
                .where(admin.firestore.FieldPath.documentId(), 'in', participantIds)
                .get()
                .then(usersSnapshot => {
                    const tokens = [];
                    usersSnapshot.forEach(userDoc => {
                        const userData = userDoc.data();
                        if (userData.fcmToken) {
                            tokens.push(userData.fcmToken);
                        }
                    });

                    if (tokens.length === 0) {
                        console.log(`No tokens found for event ${doc.id}`);
                        return;
                    }

                    // 發送多播訊息
                    const message = {
                        notification: {
                            title: '晚餐活動提醒',
                            body: '別忘了您明天晚上有晚餐聚會喔！',
                        },
                        data: {
                            actionType: 'view_event',
                            actionData: doc.id,
                            notificationId: doc.id,
                        },
                        tokens: tokens,
                    };

                    return messaging.sendMulticast(message)
                        .then((response) => {
                            console.log(`Sent reminders for event ${doc.id}: ${response.successCount} successes, ${response.failureCount} failures`);
                        });
                });

            promises.push(eventPromise);
        });

        await Promise.all(promises);
        console.log('Reminders sent successfully.');
        return null;

    } catch (error) {
        console.error('Error sending reminders:', error);
        return null;
    }
});
