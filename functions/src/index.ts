import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

/**
 * 定時活動提醒
 * 每小時執行一次，檢查即將到來的活動並發送提醒
 *
 * 規則：
 * 1. 活動前 24 小時發送提醒 (檢查窗口: 23h - 25h)
 * 2. 活動前 2 小時發送提醒 (檢查窗口: 1h - 3h)
 *
 * 依賴欄位：
 * - dinner_events/{eventId}/dateTime (Timestamp)
 * - dinner_events/{eventId}/participantIds (Array<String>)
 * - dinner_events/{eventId}/remind24hSent (Boolean)
 * - dinner_events/{eventId}/remind2hSent (Boolean)
 * - users/{userId}/fcmToken (String)
 */
export const sendEventReminders = functions.pubsub.schedule("every 60 minutes").onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();
    const nowMillis = now.toMillis();

    // 預查未來 25 小時內的活動
    const futureLimit = admin.firestore.Timestamp.fromMillis(nowMillis + 25 * 60 * 60 * 1000);

    // 查詢在時間範圍內的活動
    // 注意：Firestore 複合查詢中，範圍篩選和不等篩選不能同時作用於不同欄位。
    // 因此這裡只篩選時間，狀態在代碼中過濾。
    const snapshot = await db.collection("dinner_events")
        .where("dateTime", ">", now)
        .where("dateTime", "<=", futureLimit)
        .get();

    if (snapshot.empty) {
        console.log("No upcoming events found for reminders.");
        return null;
    }

    // 處理 Firestore 寫入限制 (每批次最多 500)
    const batches: admin.firestore.WriteBatch[] = [];
    let currentBatch = db.batch();
    let currentBatchCount = 0;

    // 定義待發送的通知任務結構
    interface SendTask {
        userIds: string[];
        title: string;
        body: string;
        eventId: string;
    }
    const sendTasks: SendTask[] = [];

    for (const doc of snapshot.docs) {
        const data = doc.data();

        // 記憶體內過濾已取消的活動
        if (data.status === 'cancelled') continue;

        const eventTime = (data.dateTime as admin.firestore.Timestamp).toMillis();
        // 計算剩餘小時數
        const diffHours = (eventTime - nowMillis) / (3600 * 1000);

        const participantIds = (data.participantIds as string[]) || [];
        if (participantIds.length === 0) continue;

        let updates: any = {};
        let updated = false;

        // 24小時提醒邏輯
        // 檢查是否在 23~25 小時範圍內，且未發送過
        if (diffHours > 23 && diffHours <= 25 && !data.remind24hSent) {
            console.log(`Scheduling 24h reminder for event ${doc.id}`);
            sendTasks.push({
                userIds: participantIds,
                title: "活動提醒",
                body: "您報名的晚餐活動將在明天舉行！別忘了準時參加喔。",
                eventId: doc.id
            });
            updates.remind24hSent = true;
            updated = true;
        }
        // 2小時提醒邏輯
        // 檢查是否在 1~3 小時範圍內，且未發送過
        else if (diffHours > 1 && diffHours <= 3 && !data.remind2hSent) {
            console.log(`Scheduling 2h reminder for event ${doc.id}`);
            sendTasks.push({
                userIds: participantIds,
                title: "即將開始",
                body: "您報名的晚餐活動將在 2 小時後開始，準備出發了嗎？",
                eventId: doc.id
            });
            updates.remind2hSent = true;
            // 如果此時才發 2h，通常意味著 24h 也過了，防止後續誤發
            if (!data.remind24hSent) updates.remind24hSent = true;
            updated = true;
        }

        if (updated) {
            currentBatch.update(doc.ref, updates);
            currentBatchCount++;

            if (currentBatchCount >= 500) {
                batches.push(currentBatch);
                currentBatch = db.batch();
                currentBatchCount = 0;
            }
        }
    }

    if (currentBatchCount > 0) {
        batches.push(currentBatch);
    }

    // 批量更新 Firestore 狀態
    if (batches.length > 0) {
        await Promise.all(batches.map(batch => batch.commit()));
        console.log(`Updated event documents in ${batches.length} batches.`);
    }

    // 執行發送任務
    // 雖然這裡使用了 await in loop，但通常任務數量不多 (每小時的活動量)
    for (const task of sendTasks) {
        await sendMulticast(task.userIds, task.title, task.body, task.eventId);
    }

    return null;
});

/**
 * 發送多播通知
 * 處理 500 個 token 限制
 */
async function sendMulticast(userIds: string[], title: string, body: string, eventId: string) {
    if (userIds.length === 0) return;

    // 1. 獲取用戶 Tokens
    // 使用 Promise.all 並行查詢
    const userDocs = await Promise.all(
        userIds.map(uid => db.collection("users").doc(uid).get())
    );

    const tokens: string[] = [];
    for (const doc of userDocs) {
        if (doc.exists) {
            const userData = doc.data();
            if (userData && userData.fcmToken) {
                // 支援單個 token 或 token 數組 (兼容性)
                if (typeof userData.fcmToken === 'string') {
                    tokens.push(userData.fcmToken);
                } else if (Array.isArray(userData.fcmToken)) {
                    tokens.push(...userData.fcmToken);
                }
            }
            // 檢查是否有 fcmTokens 數組字段 (備用)
            if (userData && userData.fcmTokens && Array.isArray(userData.fcmTokens)) {
                tokens.push(...userData.fcmTokens);
            }
        }
    }

    // 去重
    const uniqueTokens = [...new Set(tokens)];

    if (uniqueTokens.length === 0) {
        console.log(`No tokens found for users: ${userIds.join(", ")}`);
        return;
    }

    console.log(`Sending notification to ${uniqueTokens.length} tokens.`);

    // 2. 分批發送 (每批最多 500 個)
    const chunkSize = 500;
    for (let i = 0; i < uniqueTokens.length; i += chunkSize) {
        const chunk = uniqueTokens.slice(i, i + chunkSize);

        const message: admin.messaging.MulticastMessage = {
            tokens: chunk,
            notification: {
                title: title,
                body: body,
            },
            data: {
                type: "event_reminder",
                eventId: eventId,
                actionType: "view_event",
                click_action: "FLUTTER_NOTIFICATION_CLICK"
            },
            android: {
                priority: "high",
                notification: {
                    channelId: "channel_events", // 需與 NotificationChannelService 一致
                    clickAction: "FLUTTER_NOTIFICATION_CLICK"
                }
            },
            apns: {
                payload: {
                    aps: {
                        sound: "default",
                        contentAvailable: true
                    }
                }
            }
        };

        // 3. 發送
        try {
            const response = await admin.messaging().sendMulticast(message);
            console.log(`Successfully sent message chunk ${i / chunkSize + 1}: success=${response.successCount}, failure=${response.failureCount}`);

            if (response.failureCount > 0) {
                response.responses.forEach((resp, idx) => {
                    if (!resp.success) {
                        console.error(`Error sending to token ${chunk[idx]}:`, resp.error);
                    }
                });
            }
        } catch (error) {
            console.error("Error sending multicast message chunk:", error);
        }
    }
}
