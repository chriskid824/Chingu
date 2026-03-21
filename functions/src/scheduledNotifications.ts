import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const db = admin.firestore();
const messaging = admin.messaging();

// ────────────────────────────────────────────────────────
// 1. 截止提醒：每週二 18:00
//    提醒尚未報名的活躍用戶（距離截止 3 小時）
// ────────────────────────────────────────────────────────

export const sendSignupReminder = functions.pubsub
    .schedule("every tuesday 18:00")
    .timeZone("Asia/Taipei")
    .onRun(async () => {
        console.log("[sendSignupReminder] Sending signup deadline reminders...");

        // 找本週四的 open 活動
        const now = new Date();
        const thisThursday = getNextThursday(now);
        const start = new Date(thisThursday);
        start.setHours(0, 0, 0, 0);
        const end = new Date(thisThursday);
        end.setHours(23, 59, 59, 999);

        const events = await db
            .collection("dinner_events")
            .where("status", "==", "open")
            .where("eventDate", ">=", admin.firestore.Timestamp.fromDate(start))
            .where("eventDate", "<=", admin.firestore.Timestamp.fromDate(end))
            .get();

        if (events.empty) return;

        // 收集已報名的用戶
        const signedUpSet = new Set<string>();
        for (const doc of events.docs) {
            const users: string[] = doc.data().signedUpUsers || [];
            users.forEach((uid) => signedUpSet.add(uid));
        }

        // 找活躍但未報名的用戶（用 topic 推播比較省）
        // 這裡我們用 topic 'all_users' 但排除已報名者太複雜
        // 改用個別推播給未報名用戶
        const allUsers = await db
            .collection("users")
            .where("isActive", "==", true)
            .get();

        const tokens: string[] = [];
        for (const doc of allUsers.docs) {
            if (signedUpSet.has(doc.id)) continue;
            const token = doc.data().fcmToken;
            if (token) tokens.push(token);
        }

        if (tokens.length === 0) return;

        // 分批推播（每次最多 500 tokens）
        const batches = chunkArray(tokens, 500);
        for (const batch of batches) {
            await messaging.sendEachForMulticast({
                notification: {
                    title: "⏰ 還有 3 小時截止報名！",
                    body: "本週四的晚餐還有名額，快來報名和新朋友共進晚餐吧 🍽️",
                },
                data: { type: "signup_reminder" },
                apns: {
                    payload: { aps: { badge: 1, sound: "default" } },
                },
                tokens: batch,
            });
        }

        console.log(
            `[sendSignupReminder] Sent to ${tokens.length} users`
        );
    });

// ────────────────────────────────────────────────────────
// 2. 餐廳揭曉：每週四 12:00
//    更新 DinnerGroup 狀態 + 推播餐廳資訊（距離晚餐 7 小時）
// ────────────────────────────────────────────────────────

export const revealRestaurants = functions.pubsub
    .schedule("every thursday 12:00")
    .timeZone("Asia/Taipei")
    .onRun(async () => {
        console.log("[revealRestaurants] Revealing restaurants...");

        // 找今天的 closed 活動（已分桌但尚未揭曉的）
        const today = new Date();
        const start = new Date(today);
        start.setHours(0, 0, 0, 0);
        const end = new Date(today);
        end.setHours(23, 59, 59, 999);

        const events = await db
            .collection("dinner_events")
            .where("status", "==", "closed")
            .where("eventDate", ">=", admin.firestore.Timestamp.fromDate(start))
            .where("eventDate", "<=", admin.firestore.Timestamp.fromDate(end))
            .get();

        if (events.empty) return;

        for (const eventDoc of events.docs) {
            // 找到該活動的所有群組
            const groups = await db
                .collection("dinnerGroups")
                .where("eventId", "==", eventDoc.id)
                .where("status", "==", "info_revealed")
                .get();

            const allUserIds: string[] = [];

            for (const groupDoc of groups.docs) {
                // 更新狀態為 location_revealed
                await groupDoc.ref.update({
                    status: "location_revealed",
                });

                const participants: string[] =
                    groupDoc.data().participantIds || [];
                allUserIds.push(...participants);

                // 個別推播餐廳資訊給該組成員
                const restaurantName =
                    groupDoc.data().restaurantName || "驚喜餐廳";
                const restaurantAddress =
                    groupDoc.data().restaurantAddress || "";

                const userDocs = await Promise.all(
                    participants.map((uid) =>
                        db.collection("users").doc(uid).get()
                    )
                );

                const groupTokens = userDocs
                    .map((d) => d.data()?.fcmToken)
                    .filter((t): t is string => !!t);

                if (groupTokens.length > 0) {
                    await messaging.sendEachForMulticast({
                        notification: {
                            title: "🎉 餐廳揭曉！",
                            body: `今晚的餐廳是「${restaurantName}」！地址：${restaurantAddress}`,
                        },
                        data: {
                            type: "restaurant_revealed",
                            restaurantName: restaurantName,
                        },
                        apns: {
                            payload: {
                                aps: { badge: 1, sound: "default" },
                            },
                        },
                        tokens: groupTokens,
                    });
                }
            }

            console.log(
                `[revealRestaurants] Revealed ${groups.size} groups for event ${eventDoc.id}`
            );

            // 更新活動狀態
            await eventDoc.ref.update({ status: "revealed" });
        }
    });

// ────────────────────────────────────────────────────────
// 3. 評價提醒：每週五 21:00 (= 13:00 UTC)
//    活動結束後 ~24hr，提醒尚未完成評價的用戶
// ────────────────────────────────────────────────────────

export const sendReviewReminder = functions.pubsub
    .schedule("every friday 13:00")
    .timeZone("Asia/Taipei")
    .onRun(async () => {
        console.log("[sendReviewReminder] Sending review reminders...");

        // 找到 reviewStatus 不是 completed 的群組
        const groups = await db
            .collection("dinnerGroups")
            .where("status", "==", "completed")
            .where("reviewStatus", "in", ["none", "in_progress"])
            .get();

        if (groups.empty) return;

        const notifiedUserIds = new Set<string>();

        for (const groupDoc of groups.docs) {
            const participants: string[] =
                groupDoc.data().participantIds || [];
            const eventId: string = groupDoc.data().eventId || "";

            // 檢查哪些用戶尚未提交評價
            for (const userId of participants) {
                if (notifiedUserIds.has(userId)) continue;

                const existingReviews = await db
                    .collection("dinnerReviews")
                    .where("reviewerId", "==", userId)
                    .where("eventId", "==", eventId)
                    .limit(1)
                    .get();

                // 如果已有評價記錄，跳過
                if (!existingReviews.empty) continue;

                // 推播提醒
                const userDoc = await db
                    .collection("users")
                    .doc(userId)
                    .get();
                const token = userDoc.data()?.fcmToken;

                if (token) {
                    try {
                        await messaging.send({
                            notification: {
                                title: "⏰ 別忘了評價你的同桌夥伴！",
                                body: "評價即將於 24 小時後截止，完成評價才有機會解鎖聊天 💬",
                            },
                            data: {
                                type: "review_reminder",
                                groupId: groupDoc.id,
                            },
                            apns: {
                                payload: {
                                    aps: { badge: 1, sound: "default" },
                                },
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

        console.log(
            `[sendReviewReminder] Reminded ${notifiedUserIds.size} users`
        );
    });

// ────────────────────────────────────────────────────────
// Helpers
// ────────────────────────────────────────────────────────

function getNextThursday(from: Date): Date {
    const d = new Date(from);
    const day = d.getDay();
    const diff = (4 - day + 7) % 7 || 7;
    d.setDate(d.getDate() + diff);
    return d;
}

function chunkArray<T>(array: T[], chunkSize: number): T[][] {
    const chunks: T[][] = [];
    for (let i = 0; i < array.length; i += chunkSize) {
        chunks.push(array.slice(i, i + chunkSize));
    }
    return chunks;
}

// ────────────────────────────────────────────────────────
// 4. 活動完成：每週四 22:00
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

        // 找今天的活動
        const events = await db
            .collection("dinner_events")
            .where("status", "in", ["closed", "revealed"])
            .where("eventDate", ">=", admin.firestore.Timestamp.fromDate(start))
            .where("eventDate", "<=", admin.firestore.Timestamp.fromDate(end))
            .get();

        if (events.empty) return;

        for (const eventDoc of events.docs) {
            // 更新活動狀態
            await eventDoc.ref.update({ status: "completed" });

            // 更新所有群組狀態
            const groups = await db
                .collection("dinnerGroups")
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
