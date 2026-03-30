import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const db = admin.firestore();
const messaging = admin.messaging();

// ────────────────────────────────────────────────────────
// 1. 報名開放提醒：每週二 凌晨（活動建立後）
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
        }

        console.log(`[sendSignupReminder] Sent to ${tokens.length} users`);
    });

// ────────────────────────────────────────────────────────
// 2. 餐廳揭曉 + 建立群組聊天：每週三 17:00
//    更新 DinnerGroup 狀態 + 建立群組聊天室 + 推播
// ────────────────────────────────────────────────────────

export const revealRestaurants = functions.pubsub
    .schedule("every wednesday 17:00")
    .timeZone("Asia/Taipei")
    .onRun(async () => {
        console.log("[revealRestaurants] Revealing restaurants + creating group chats...");

        // 找明天（週四）的已配對活動
        const tomorrow = new Date();
        tomorrow.setDate(tomorrow.getDate() + 1);
        const start = new Date(tomorrow);
        start.setHours(0, 0, 0, 0);
        const end = new Date(tomorrow);
        end.setHours(23, 59, 59, 999);

        const events = await db
            .collection("dinner_events")
            .where("status", "==", "closed")
            .where("eventDate", ">=", admin.firestore.Timestamp.fromDate(start))
            .where("eventDate", "<=", admin.firestore.Timestamp.fromDate(end))
            .get();

        if (events.empty) return;

        for (const eventDoc of events.docs) {
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

                // 更新狀態為 location_revealed
                await groupDoc.ref.update({
                    status: "location_revealed",
                });

                // 建立群組聊天室
                const chatRoomRef = db.collection("chat_rooms").doc();
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
                    lastMessage: "群組聊天已開通！明晚見～",
                    lastMessageTime: admin.firestore.FieldValue.serverTimestamp(),
                    lastMessageSenderId: "system",
                    unreadCount: unreadCount,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                });

                // 寫入系統歡迎訊息
                await chatRoomRef.collection("messages").add({
                    chatRoomId: chatRoomRef.id,
                    senderId: "system",
                    senderName: "Chingu",
                    message: "群組聊天已開通！明晚見～有任何問題可以在這裡討論。",
                    type: "system",
                    timestamp: admin.firestore.FieldValue.serverTimestamp(),
                    readBy: [],
                });

                // 更新 DinnerGroup 的 groupChatId
                await groupDoc.ref.update({
                    groupChatId: chatRoomRef.id,
                });

                // 推播餐廳資訊
                if (groupTokens.length > 0) {
                    await messaging.sendEachForMulticast({
                        notification: {
                            title: "餐廳揭曉",
                            body: `明晚的餐廳已確認！點擊查看地址與導航。`,
                        },
                        data: {
                            type: "restaurant_revealed",
                            restaurantName: restaurantName,
                            restaurantAddress: restaurantAddress,
                        },
                        apns: {
                            payload: { aps: { badge: 1, sound: "default" } },
                        },
                        tokens: groupTokens,
                    });
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
// 3. 晚餐提醒：每週四 18:00
//    提醒參與者今晚見 + 打開破冰話題包
// ────────────────────────────────────────────────────────

export const sendDinnerReminder = functions.pubsub
    .schedule("every thursday 18:00")
    .timeZone("Asia/Taipei")
    .onRun(async () => {
        console.log("[sendDinnerReminder] Sending dinner reminders...");

        const today = new Date();
        const start = new Date(today);
        start.setHours(0, 0, 0, 0);
        const end = new Date(today);
        end.setHours(23, 59, 59, 999);

        const groups = await db
            .collection("dinner_groups")
            .where("status", "==", "location_revealed")
            .get();

        const allTokens: string[] = [];

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

        if (allTokens.length === 0) return;

        const batches = chunkArray(allTokens, 500);
        for (const batch of batches) {
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
        }

        console.log(`[sendDinnerReminder] Sent to ${allTokens.length} users`);
    });

// ────────────────────────────────────────────────────────
// 4. 照片解鎖：每週四 19:00
//    更新群組聊天室的 participantAvatars 為真實照片
// ────────────────────────────────────────────────────────

export const unlockPhotos = functions.pubsub
    .schedule("every thursday 19:00")
    .timeZone("Asia/Taipei")
    .onRun(async () => {
        console.log("[unlockPhotos] Unlocking photos in group chats...");

        // 找今天 location_revealed 的群組
        const groups = await db
            .collection("dinner_groups")
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

            // 更新群組聊天室的照片
            await db.collection("chat_rooms").doc(groupChatId).update({
                participantAvatars: avatars,
            });
        }

        console.log(`[unlockPhotos] Unlocked photos for ${groups.size} groups`);
    });

// ────────────────────────────────────────────────────────
// 5. 活動完成：每週四 22:00
//    將 DinnerGroup 狀態從 location_revealed → completed
// ────────────────────────────────────────────────────────

export const completeEvents = functions.pubsub
    .schedule("every thursday 22:00")
    .timeZone("Asia/Taipei")
    .onRun(async () => {
        console.log("[completeEvents] Marking events as completed...");

        const today = new Date();
        const start = new Date(today);
        start.setHours(0, 0, 0, 0);
        const end = new Date(today);
        end.setHours(23, 59, 59, 999);

        const events = await db
            .collection("dinner_events")
            .where("status", "in", ["closed", "revealed"])
            .where("eventDate", ">=", admin.firestore.Timestamp.fromDate(start))
            .where("eventDate", "<=", admin.firestore.Timestamp.fromDate(end))
            .get();

        if (events.empty) return;

        for (const eventDoc of events.docs) {
            await eventDoc.ref.update({ status: "completed" });

            const groups = await db
                .collection("dinner_groups")
                .where("eventId", "==", eventDoc.id)
                .where("status", "==", "location_revealed")
                .get();

            for (const groupDoc of groups.docs) {
                await groupDoc.ref.update({ status: "completed" });
            }

            console.log(
                `[completeEvents] Event ${eventDoc.id}: ${groups.size} groups completed`
            );
        }
    });

// ────────────────────────────────────────────────────────
// 6. 評價提醒：每週五 10:00
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
            const eventId: string = groupDoc.data().eventId || "";

            for (const userId of participants) {
                if (notifiedUserIds.has(userId)) continue;

                const existingReviews = await db
                    .collection("dinner_reviews")
                    .where("reviewerId", "==", userId)
                    .where("eventId", "==", eventId)
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
// 7. 評價截止提醒：每週日 10:00（截止前 ~24hr）
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
            const eventId: string = groupDoc.data().eventId || "";

            for (const userId of participants) {
                if (notifiedUserIds.has(userId)) continue;

                const existingReviews = await db
                    .collection("dinner_reviews")
                    .where("reviewerId", "==", userId)
                    .where("eventId", "==", eventId)
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
// 8. 自動跳過評價：每週一 10:00（週四晚餐後 72hr+）
//    未評價的自動視為全部 'skipped'
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

        let skippedCount = 0;

        for (const groupDoc of groups.docs) {
            const participants: string[] = groupDoc.data().participantIds || [];
            const eventId: string = groupDoc.data().eventId || "";

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
                for (const revieweeId of pendingReviewees) {
                    await db.collection("dinner_reviews").add({
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
