import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { taipeiDayWindowUtc } from "./taipeiTime";

const db = admin.firestore();
const messaging = admin.messaging();

// 評價期限:晚餐(週四)結束後 72 小時
const REVIEW_WINDOW_MS = 72 * 60 * 60 * 1000;

/** 取台北「今天+offsetDays」整日視窗內的 dinner_events(依 status 過濾) */
async function eventsInTaipeiDay(
    offsetDays: number,
    statuses: string[]
): Promise<admin.firestore.QueryDocumentSnapshot[]> {
    const at = new Date(Date.now() + offsetDays * 24 * 60 * 60 * 1000);
    const { start, end } = taipeiDayWindowUtc(at);
    const snap = await db
        .collection("dinner_events")
        .where("status", "in", statuses)
        .where("eventDate", ">=", admin.firestore.Timestamp.fromDate(start))
        .where("eventDate", "<=", admin.firestore.Timestamp.fromDate(end))
        .get();
    return snap.docs;
}

// ────────────────────────────────────────────────────────
// 1. 報名開放提醒：每週二 08:00(台北)
//    提醒所有活躍用戶本週四晚餐開放報名
// ────────────────────────────────────────────────────────

export const sendSignupReminder = functions.pubsub
    .schedule("every tuesday 08:00")
    .timeZone("Asia/Taipei")
    .onRun(async () => {
        console.log("[sendSignupReminder] Sending signup open reminders...");

        const allUsers = await db
            .collection("users")
            .where("isActive", "==", true)
            .get();

        const tokens: string[] = [];
        for (const doc of allUsers.docs) {
            const token = doc.data().fcmToken;
            if (token) tokens.push(token);
        }

        if (tokens.length === 0) return;

        const batches = chunkArray(tokens, 500);
        for (const batch of batches) {
            try {
                await messaging.sendEachForMulticast({
                    notification: {
                        title: "本週四晚餐開放報名",
                        body: "新的一週，新的相遇。來報名本週四的晚餐吧！",
                    },
                    data: { type: "signup_open" },
                    apns: {
                        payload: { aps: { badge: 1, sound: "default" } },
                    },
                    tokens: batch,
                });
            } catch (e) {
                console.error("[sendSignupReminder] batch failed:", e);
            }
        }

        console.log(`[sendSignupReminder] Sent to ${tokens.length} users`);
    });

// ────────────────────────────────────────────────────────
// 2. 餐廳揭曉 + 建立群組聊天：每週三 17:00(台北)
//    建立群組聊天室 → 最後才更新狀態(失敗重跑不會卡死)
// ────────────────────────────────────────────────────────

export const revealRestaurants = functions.pubsub
    .schedule("every wednesday 17:00")
    .timeZone("Asia/Taipei")
    .onRun(async () => {
        console.log("[revealRestaurants] Revealing restaurants + creating group chats...");

        // 找台北時間「明天(週四)」的已配對活動
        const events = await eventsInTaipeiDay(1, ["closed"]);
        if (events.length === 0) return;

        for (const eventDoc of events) {
            const groups = await db
                .collection("dinner_groups")
                .where("eventId", "==", eventDoc.id)
                .where("status", "==", "info_revealed")
                .get();

            for (const groupDoc of groups.docs) {
                const groupData = groupDoc.data();
                const participants: string[] = groupData.participantIds || [];
                const restaurantName = groupData.restaurantName || "驚喜餐廳";
                const restaurantAddress = groupData.restaurantAddress || "";

                // 確定性聊天室 id:重跑覆寫同一間,不會重複建
                const chatRoomRef = db
                    .collection("chat_rooms")
                    .doc(`group_${groupDoc.id}`);

                const participantNames: Record<string, string> = {};
                const participantAvatars: Record<string, string | null> = {};
                const unreadCount: Record<string, number> = {};

                const userDocs = await Promise.all(
                    participants.map((uid) =>
                        db.collection("users").doc(uid).get()
                    )
                );

                const groupTokens: string[] = [];

                for (const userDoc of userDocs) {
                    if (!userDoc.exists) continue;
                    const data = userDoc.data()!;
                    participantNames[userDoc.id] = data.name || "匿名";
                    participantAvatars[userDoc.id] = null; // 照片週四 19:00 才解鎖
                    unreadCount[userDoc.id] = 1; // 系統訊息算一則未讀
                    if (data.fcmToken) groupTokens.push(data.fcmToken);
                }

                await chatRoomRef.set({
                    type: "group",
                    dinnerEventId: eventDoc.id,
                    groupId: groupDoc.id,
                    participantIds: participants,
                    participantNames: participantNames,
                    participantAvatars: participantAvatars,
                    photosUnlocked: false,
                    lastMessage: "群組聊天已開通！明晚見～",
                    lastMessageAt: admin.firestore.FieldValue.serverTimestamp(),
                    lastMessageTime: admin.firestore.FieldValue.serverTimestamp(),
                    lastMessageSenderId: "system",
                    unreadCount: unreadCount,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                });

                // 寫入系統歡迎訊息(欄位統一用 text,client UI 讀 text)
                // 只在尚未寫過時寫入(重跑不重複)
                if (!groupData.groupChatId) {
                    await chatRoomRef.collection("messages").add({
                        chatRoomId: chatRoomRef.id,
                        senderId: "system",
                        senderName: "Chingu",
                        text: "群組聊天已開通！明晚見～有任何問題可以在這裡討論。",
                        type: "system",
                        timestamp: admin.firestore.FieldValue.serverTimestamp(),
                        isRead: false,
                        readBy: [],
                    });
                }

                // 所有副作用完成後才更新狀態(中途失敗重跑仍抓得到這組)
                await groupDoc.ref.update({
                    groupChatId: chatRoomRef.id,
                    status: "location_revealed",
                });

                // 推播餐廳資訊
                if (groupTokens.length > 0) {
                    const batches = chunkArray(groupTokens, 500);
                    for (const batch of batches) {
                        try {
                            await messaging.sendEachForMulticast({
                                notification: {
                                    title: "餐廳揭曉",
                                    body: "明晚的餐廳已確認！點擊查看地址與導航。",
                                },
                                data: {
                                    type: "restaurant_revealed",
                                    restaurantName: restaurantName,
                                    restaurantAddress: restaurantAddress,
                                },
                                apns: {
                                    payload: { aps: { badge: 1, sound: "default" } },
                                },
                                tokens: batch,
                            });
                        } catch (e) {
                            console.error("[revealRestaurants] push failed:", e);
                        }
                    }
                }
            }

            // 更新活動狀態
            await eventDoc.ref.update({ status: "revealed" });

            console.log(
                `[revealRestaurants] Revealed ${groups.size} groups for event ${eventDoc.id}`
            );
        }
    });

// ────────────────────────────────────────────────────────
// 3. 晚餐提醒：每週四 18:00(台北)
//    只提醒「今天」場次的參與者(不掃全部 location_revealed)
// ────────────────────────────────────────────────────────

export const sendDinnerReminder = functions.pubsub
    .schedule("every thursday 18:00")
    .timeZone("Asia/Taipei")
    .onRun(async () => {
        console.log("[sendDinnerReminder] Sending dinner reminders...");

        const events = await eventsInTaipeiDay(0, ["revealed", "closed"]);
        if (events.length === 0) return;

        const allTokens: string[] = [];

        for (const eventDoc of events) {
            const groups = await db
                .collection("dinner_groups")
                .where("eventId", "==", eventDoc.id)
                .where("status", "==", "location_revealed")
                .get();

            for (const groupDoc of groups.docs) {
                const participants: string[] = groupDoc.data().participantIds || [];
                const userDocs = await Promise.all(
                    participants.map((uid) => db.collection("users").doc(uid).get())
                );
                for (const doc of userDocs) {
                    const token = doc.data()?.fcmToken;
                    if (token) allTokens.push(token);
                }
            }
        }

        if (allTokens.length === 0) return;

        const batches = chunkArray(allTokens, 500);
        for (const batch of batches) {
            try {
                await messaging.sendEachForMulticast({
                    notification: {
                        title: "今晚見",
                        body: "晚餐即將開始，記得打開破冰話題包！",
                    },
                    data: { type: "dinner_reminder" },
                    apns: {
                        payload: { aps: { badge: 1, sound: "default" } },
                    },
                    tokens: batch,
                });
            } catch (e) {
                console.error("[sendDinnerReminder] batch failed:", e);
            }
        }

        console.log(`[sendDinnerReminder] Sent to ${allTokens.length} users`);
    });

// ────────────────────────────────────────────────────────
// 4. 照片解鎖：每週四 19:00(台北)
//    更新「今天」場次群組聊天室的 participantAvatars 為真實照片
// ────────────────────────────────────────────────────────

export const unlockPhotos = functions.pubsub
    .schedule("every thursday 19:00")
    .timeZone("Asia/Taipei")
    .onRun(async () => {
        console.log("[unlockPhotos] Unlocking photos in group chats...");

        const events = await eventsInTaipeiDay(0, ["revealed", "closed"]);
        let unlocked = 0;

        for (const eventDoc of events) {
            const groups = await db
                .collection("dinner_groups")
                .where("eventId", "==", eventDoc.id)
                .where("status", "==", "location_revealed")
                .get();

            for (const groupDoc of groups.docs) {
                const groupChatId = groupDoc.data().groupChatId;
                if (!groupChatId) continue;

                const participants: string[] = groupDoc.data().participantIds || [];

                // 取得所有成員的真實照片
                const userDocs = await Promise.all(
                    participants.map((uid) => db.collection("users").doc(uid).get())
                );

                const avatars: Record<string, string | null> = {};
                for (const userDoc of userDocs) {
                    if (!userDoc.exists) continue;
                    avatars[userDoc.id] = userDoc.data()?.avatarUrl || null;
                }

                // 更新群組聊天室的照片 + 解鎖旗標(推播匿名判斷用)
                await db.collection("chat_rooms").doc(groupChatId).update({
                    participantAvatars: avatars,
                    photosUnlocked: true,
                });
                unlocked++;
            }
        }

        console.log(`[unlockPhotos] Unlocked photos for ${unlocked} groups`);
    });

// ────────────────────────────────────────────────────────
// 5. 活動完成：每週四 22:00(台北)
//    先改 groups、記 completedAt,最後才改 event(失敗重跑不卡死)
// ────────────────────────────────────────────────────────

export const completeEvents = functions.pubsub
    .schedule("every thursday 22:00")
    .timeZone("Asia/Taipei")
    .onRun(async () => {
        console.log("[completeEvents] Marking events as completed...");

        const events = await eventsInTaipeiDay(0, ["closed", "revealed"]);
        if (events.length === 0) return;

        for (const eventDoc of events) {
            const groups = await db
                .collection("dinner_groups")
                .where("eventId", "==", eventDoc.id)
                .where("status", "==", "location_revealed")
                .get();

            for (const groupDoc of groups.docs) {
                await groupDoc.ref.update({
                    status: "completed",
                    completedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
            }

            // groups 全部處理完才改 event,中途失敗重跑仍抓得到
            await eventDoc.ref.update({ status: "completed" });

            console.log(
                `[completeEvents] Event ${eventDoc.id}: ${groups.size} groups completed`
            );
        }
    });

// ────────────────────────────────────────────────────────
// 6. 評價提醒：每週五 10:00(台北)
//    提醒尚未完成評價的用戶
// ────────────────────────────────────────────────────────

export const sendReviewReminder = functions.pubsub
    .schedule("every friday 10:00")
    .timeZone("Asia/Taipei")
    .onRun(async () => {
        console.log("[sendReviewReminder] Sending review reminders...");

        const groups = await db
            .collection("dinner_groups")
            .where("status", "==", "completed")
            .where("reviewStatus", "in", ["none", "in_progress"])
            .get();

        if (groups.empty) return;

        const notifiedUserIds = new Set<string>();

        for (const groupDoc of groups.docs) {
            const participants: string[] = groupDoc.data().participantIds || [];

            for (const userId of participants) {
                if (notifiedUserIds.has(userId)) continue;

                // 以 groupId 判斷是否已評(與 autoSkipReviews 一致)
                const existingReviews = await db
                    .collection("dinner_reviews")
                    .where("reviewerId", "==", userId)
                    .where("groupId", "==", groupDoc.id)
                    .limit(1)
                    .get();

                if (!existingReviews.empty) continue;

                const userDoc = await db.collection("users").doc(userId).get();
                const token = userDoc.data()?.fcmToken;

                if (token) {
                    try {
                        await messaging.send({
                            notification: {
                                title: "昨晚如何？",
                                body: "為你的飯友留下評價，也許會解鎖新朋友喔！",
                            },
                            data: {
                                type: "review_reminder",
                                groupId: groupDoc.id,
                            },
                            apns: {
                                payload: { aps: { badge: 1, sound: "default" } },
                            },
                            token: token,
                        });
                    } catch (e) {
                        // Ignore individual send failures
                    }
                }

                notifiedUserIds.add(userId);
            }
        }

        console.log(`[sendReviewReminder] Reminded ${notifiedUserIds.size} users`);
    });

// ────────────────────────────────────────────────────────
// 7. 評價截止提醒：每週日 10:00(台北,截止前 ~24hr)
// ────────────────────────────────────────────────────────

export const sendReviewUrgentReminder = functions.pubsub
    .schedule("every sunday 10:00")
    .timeZone("Asia/Taipei")
    .onRun(async () => {
        console.log("[sendReviewUrgentReminder] Sending urgent review reminders...");

        const groups = await db
            .collection("dinner_groups")
            .where("status", "==", "completed")
            .where("reviewStatus", "in", ["none", "in_progress"])
            .get();

        if (groups.empty) return;

        const notifiedUserIds = new Set<string>();

        for (const groupDoc of groups.docs) {
            const participants: string[] = groupDoc.data().participantIds || [];

            for (const userId of participants) {
                if (notifiedUserIds.has(userId)) continue;

                const existingReviews = await db
                    .collection("dinner_reviews")
                    .where("reviewerId", "==", userId)
                    .where("groupId", "==", groupDoc.id)
                    .limit(1)
                    .get();

                if (!existingReviews.empty) continue;

                const userDoc = await db.collection("users").doc(userId).get();
                const token = userDoc.data()?.fcmToken;

                if (token) {
                    try {
                        await messaging.send({
                            notification: {
                                title: "評價即將截止",
                                body: "還有 24 小時可以為飯友評價，別錯過了。",
                            },
                            data: {
                                type: "review_urgent",
                                groupId: groupDoc.id,
                            },
                            apns: {
                                payload: { aps: { badge: 1, sound: "default" } },
                            },
                            token: token,
                        });
                    } catch (e) {
                        // Ignore individual send failures
                    }
                }

                notifiedUserIds.add(userId);
            }
        }

        console.log(`[sendReviewUrgentReminder] Reminded ${notifiedUserIds.size} users`);
    });

// ────────────────────────────────────────────────────────
// 8. 自動跳過評價：每週一 10:00(台北)
//    completedAt 超過 72hr 的群組,未評價自動視為 'skipped'
// ────────────────────────────────────────────────────────

export const autoSkipReviews = functions.pubsub
    .schedule("every monday 10:00")
    .timeZone("Asia/Taipei")
    .onRun(async () => {
        console.log("[autoSkipReviews] Auto-skipping expired reviews...");

        const groups = await db
            .collection("dinner_groups")
            .where("status", "==", "completed")
            .where("reviewStatus", "in", ["none", "in_progress"])
            .get();

        if (groups.empty) return;

        const cutoff = Date.now() - REVIEW_WINDOW_MS;
        let skippedCount = 0;

        for (const groupDoc of groups.docs) {
            const data = groupDoc.data();

            // 未滿 72 小時的群組先跳過(下週再處理);
            // 沒有 completedAt 的舊資料維持原行為(直接結算)
            const completedAt = data.completedAt as
                | admin.firestore.Timestamp
                | undefined;
            if (completedAt && completedAt.toMillis() > cutoff) {
                continue;
            }

            const participants: string[] = data.participantIds || [];
            const eventId: string = data.eventId || "";

            for (const userId of participants) {
                // 找出這個人還沒評價的對象
                const existingReviews = await db
                    .collection("dinner_reviews")
                    .where("reviewerId", "==", userId)
                    .where("groupId", "==", groupDoc.id)
                    .get();

                const reviewedIds = new Set(
                    existingReviews.docs.map((d) => d.data().revieweeId)
                );

                const pendingReviewees = participants.filter(
                    (id) => id !== userId && !reviewedIds.has(id)
                );

                // 為每個未評價的對象自動建立 'skipped' 評價
                // 確定性 doc id:與 client 提交同一套規則,重跑/競態不會重複
                for (const revieweeId of pendingReviewees) {
                    const reviewId = `${userId}_${revieweeId}_${groupDoc.id}`;
                    await db.collection("dinner_reviews").doc(reviewId).set({
                        reviewerId: userId,
                        revieweeId: revieweeId,
                        groupId: groupDoc.id,
                        eventId: eventId,
                        result: "skipped",
                        createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    });
                    skippedCount++;
                }
            }

            // 更新群組評價狀態
            await groupDoc.ref.update({ reviewStatus: "completed" });
        }

        console.log(`[autoSkipReviews] Created ${skippedCount} skipped reviews`);
    });

// ────────────────────────────────────────────────────────
// Helpers
// ────────────────────────────────────────────────────────

function chunkArray<T>(array: T[], chunkSize: number): T[][] {
    const chunks: T[][] = [];
    for (let i = 0; i < array.length; i += chunkSize) {
        chunks.push(array.slice(i, i + chunkSize));
    }
    return chunks;
}
