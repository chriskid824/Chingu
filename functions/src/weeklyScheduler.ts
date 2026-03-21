import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { assignRestaurant } from "./restaurantAssignment";

const db = admin.firestore();

// ────────────────────────────────────────────────────────
// 破冰問題資料庫
// ────────────────────────────────────────────────────────
const ICEBREAKER_POOL = [
    "如果可以和世界上任何人共進晚餐，你會選誰？",
    "你最近看過最好看的電影/劇是什麼？",
    "如果明天不用上班，你會做什麼？",
    "你的 comfort food 是什麼？",
    "你去過最喜歡的旅行目的地是哪裡？",
    "小時候你想長大後做什麼？現在呢？",
    "你最近學到的一件新事物是什麼？",
    "形容今天心情的一首歌是什麼？",
    "你覺得一個好的朋友最重要的特質是什麼？",
    "你最引以為傲的一道自己煮的菜是什麼？",
    "如果你可以瞬間學會一個新技能，你會選什麼？",
    "你覺得台北最被低估的一家餐廳是？",
];

function pickIcebreakers(count: number): string[] {
    const shuffled = [...ICEBREAKER_POOL].sort(() => Math.random() - 0.5);
    return shuffled.slice(0, count);
}

// ────────────────────────────────────────────────────────
// 每週二 21:00 截止報名 + 自動分桌
// ────────────────────────────────────────────────────────

/**
 * processWeeklyGrouping
 *
 * 排程觸發：每週二 21:00 台北時間
 *
 * 流程：
 * 1. 找出本週四的所有 open 活動
 * 2. 按城市+區域分組報名者
 * 3. 每 6 人一桌（最少 4 人，不足的合併或取消）
 * 4. 為每桌指派餐廳
 * 5. 建立 DinnerGroup
 * 6. 更新 DinnerEvent 狀態為 closed
 * 7. 推播通知所有報名者
 */
export const processWeeklyGrouping = functions.pubsub
    .schedule("every tuesday 21:00")
    .timeZone("Asia/Taipei")
    .onRun(async () => {
        console.log("[processWeeklyGrouping] Starting weekly grouping...");

        // 1. 找到本週四的活動（status = 'open'）
        const now = new Date();
        const thisThursday = getNextThursday(now);
        const thursdayStart = new Date(thisThursday);
        thursdayStart.setHours(0, 0, 0, 0);
        const thursdayEnd = new Date(thisThursday);
        thursdayEnd.setHours(23, 59, 59, 999);

        const eventsSnapshot = await db
            .collection("dinner_events")
            .where("status", "==", "open")
            .where(
                "eventDate",
                ">=",
                admin.firestore.Timestamp.fromDate(thursdayStart)
            )
            .where(
                "eventDate",
                "<=",
                admin.firestore.Timestamp.fromDate(thursdayEnd)
            )
            .get();

        if (eventsSnapshot.empty) {
            console.log("[processWeeklyGrouping] No open events for Thursday");
            return;
        }

        let totalGroups = 0;
        let totalCancelled = 0;

        for (const eventDoc of eventsSnapshot.docs) {
            const eventData = eventDoc.data();
            const eventId = eventDoc.id;
            const signedUpUsers: string[] = eventData.signedUpUsers || [];
            const city: string = eventData.city || "台北市";

            console.log(
                `[processWeeklyGrouping] Event ${eventId}: ${signedUpUsers.length} users`
            );

            if (signedUpUsers.length < 4) {
                // 人數不足：取消活動 + 通知
                await handleInsufficientUsers(eventId, signedUpUsers);
                totalCancelled++;
                continue;
            }

            // 2. 取得用戶資料以按區域分組
            const userDocs = await Promise.all(
                signedUpUsers.map((uid) =>
                    db.collection("users").doc(uid).get()
                )
            );

            const usersByDistrict: Map<
                string,
                { uid: string; data: admin.firestore.DocumentData }[]
            > = new Map();

            for (const userDoc of userDocs) {
                if (!userDoc.exists) continue;
                const data = userDoc.data()!;
                const district: string = data.district || "信義區";

                if (!usersByDistrict.has(district)) {
                    usersByDistrict.set(district, []);
                }
                usersByDistrict.get(district)!.push({
                    uid: userDoc.id,
                    data: data,
                });
            }

            // 3. 分桌
            const groups = createSmartGroups(
                Array.from(usersByDistrict.entries()),
                city
            );

            // 4. 為每桌建立 DinnerGroup + 指派餐廳
            for (const group of groups) {
                const groupRef = db.collection("dinnerGroups").doc();
                const icebreakers = pickIcebreakers(3);

                await groupRef.set({
                    eventId: eventId,
                    participantIds: group.participantIds,
                    status: "pending",
                    reviewStatus: "none",
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    icebreakerQuestions: icebreakers,
                    restaurantId: null,
                    restaurantName: null,
                    restaurantAddress: null,
                    restaurantLocation: null,
                    restaurantPhone: null,
                    restaurantImageUrl: null,
                });

                // 指派餐廳
                try {
                    await assignRestaurant(
                        groupRef.id,
                        group.participantIds,
                        city,
                        group.district
                    );
                } catch (error) {
                    console.error(
                        `[processWeeklyGrouping] Restaurant assignment failed for group ${groupRef.id}:`,
                        error
                    );
                }

                totalGroups++;
            }

            // 5. 更新活動狀態
            await db.collection("dinner_events").doc(eventId).update({
                status: "closed",
            });

            // 6. 推播通知所有報名者
            await notifyGroupedUsers(signedUpUsers, eventData.eventDate);
        }

        console.log(
            `[processWeeklyGrouping] Complete. Groups: ${totalGroups}, Cancelled: ${totalCancelled}`
        );
    });

// ────────────────────────────────────────────────────────
// 智能配對演算法
// ────────────────────────────────────────────────────────

interface UserProfile {
    uid: string;
    gender: string;
    interests: string[];
    age: number;
    budgetRange: number;
    district: string;
}

interface GroupResult {
    participantIds: string[];
    district: string;
}

/**
 * 智能配對 — 性別平衡 + 興趣相容 + 年齡/預算考量
 *
 * 流程：
 * 1. 按區域分池
 * 2. 每池內按性別分成 male/female/other
 * 3. 交替取人組成 6 人桌（盡量 3:3）
 * 4. 計算桌分 → swap optimization
 * 5. 溢出池處理
 */
function createSmartGroups(
    districtEntries: [
        string,
        { uid: string; data: admin.firestore.DocumentData }[],
    ][],
    _city: string
): GroupResult[] {
    const groups: GroupResult[] = [];
    let overflow: UserProfile[] = [];

    for (const [district, users] of districtEntries) {
        // 轉為 UserProfile
        const profiles: UserProfile[] = users.map((u) => ({
            uid: u.uid,
            gender: u.data.gender || "undisclosed",
            interests: u.data.interests || [],
            age: u.data.age || 25,
            budgetRange: u.data.budgetRange ?? 1,
            district: district,
        }));

        // 性別分池
        const males = profiles.filter((p) => p.gender === "male");
        const females = profiles.filter((p) => p.gender === "female");
        const others = profiles.filter(
            (p) => p.gender !== "male" && p.gender !== "female"
        );

        // 隨機打散各池
        shuffle(males);
        shuffle(females);
        shuffle(others);

        // 交替組桌（目標 3:3，彈性 2:4 ~ 4:2）
        const districtGroups = genderBalancedSplit(
            males,
            females,
            others,
            district
        );

        // swap optimization
        if (districtGroups.length >= 2) {
            swapOptimize(districtGroups, 50);
        }

        // 分離正式組和溢出
        for (const g of districtGroups) {
            if (g.members.length >= 4) {
                groups.push({
                    participantIds: g.members.map((m) => m.uid),
                    district: district,
                });
            } else {
                overflow.push(...g.members);
            }
        }
    }

    // 溢出池處理
    if (overflow.length >= 4) {
        shuffle(overflow);
        let i = 0;
        while (i + 4 <= overflow.length) {
            const take = Math.min(6, overflow.length - i);
            groups.push({
                participantIds: overflow.slice(i, i + take).map((u) => u.uid),
                district: overflow[i].district || "信義區",
            });
            i += take;
        }
        // 剩餘不足 4 人 → 併入最後一組
        if (i < overflow.length && groups.length > 0) {
            const lastGroup = groups[groups.length - 1];
            for (let j = i; j < overflow.length; j++) {
                lastGroup.participantIds.push(overflow[j].uid);
            }
        }
    } else if (overflow.length > 0 && groups.length > 0) {
        // 分散併入（不超過 8 人）
        for (const user of overflow) {
            const smallest = groups
                .filter((g) => g.participantIds.length < 8)
                .reduce(
                    (a, b) =>
                        a.participantIds.length <= b.participantIds.length
                            ? a
                            : b,
                    groups[0]
                );
            smallest.participantIds.push(user.uid);
        }
    }

    return groups;
}

// ─── 性別平衡分桌 ───

interface SmartGroup {
    members: UserProfile[];
    district: string;
}

function genderBalancedSplit(
    males: UserProfile[],
    females: UserProfile[],
    others: UserProfile[],
    district: string
): SmartGroup[] {
    const totalPeople = males.length + females.length + others.length;
    if (totalPeople === 0) return [];

    const numTables = Math.ceil(totalPeople / 6);
    if (numTables === 0) return [];

    // 初始化空桌
    const groups: SmartGroup[] = Array.from({ length: numTables }, () => ({
        members: [],
        district,
    }));

    // 決定多數/少數性別
    const majority = males.length >= females.length ? males : females;
    const minority = males.length >= females.length ? females : males;

    // Step 1: 少數性別均勻分配到各桌（Round-robin）
    for (let i = 0; i < minority.length; i++) {
        groups[i % numTables].members.push(minority[i]);
    }

    // Step 2: 多數性別均勻分配（Round-robin）
    for (let i = 0; i < majority.length; i++) {
        // 找當前最少人的桌子
        const target = groups.reduce((a, b) =>
            a.members.length <= b.members.length ? a : b
        );
        target.members.push(majority[i]);
    }

    // Step 3: others 均勻分配
    for (let i = 0; i < others.length; i++) {
        const target = groups.reduce((a, b) =>
            a.members.length <= b.members.length ? a : b
        );
        target.members.push(others[i]);
    }

    return groups;
}

// ─── 評分函式 ───

function calculateGroupScore(members: UserProfile[]): number {
    if (members.length < 2) return 0;

    // 1. 興趣相容度（平均 Jaccard 係數）
    let totalJaccard = 0;
    let pairs = 0;

    for (let i = 0; i < members.length; i++) {
        for (let j = i + 1; j < members.length; j++) {
            totalJaccard += jaccardSimilarity(
                members[i].interests,
                members[j].interests
            );
            pairs++;
        }
    }
    const interestScore = pairs > 0 ? totalJaccard / pairs : 0;

    // 2. 年齡差異懲罰
    const ages = members.map((m) => m.age);
    const agePenalty = stdDev(ages) / 10;

    // 3. 預算一致性懲罰
    const budgets = members.map((m) => m.budgetRange);
    const budgetPenalty = stdDev(budgets) * 0.1;

    // 4. 性別平衡獎勵
    const maleCount = members.filter((m) => m.gender === "male").length;
    const femaleCount = members.filter((m) => m.gender === "female").length;
    const genderBalance =
        members.length > 0
            ? 1 - Math.abs(maleCount - femaleCount) / members.length
            : 0;
    const genderBonus = genderBalance * 0.3;

    return interestScore + genderBonus - agePenalty - budgetPenalty;
}

function jaccardSimilarity(a: string[], b: string[]): number {
    if (a.length === 0 && b.length === 0) return 0;
    const setA = new Set(a);
    const setB = new Set(b);
    const intersection = [...setA].filter((x) => setB.has(x)).length;
    const union = new Set([...setA, ...setB]).size;
    return union > 0 ? intersection / union : 0;
}

function stdDev(arr: number[]): number {
    if (arr.length < 2) return 0;
    const mean = arr.reduce((s, v) => s + v, 0) / arr.length;
    const variance =
        arr.reduce((s, v) => s + (v - mean) ** 2, 0) / arr.length;
    return Math.sqrt(variance);
}

// ─── Swap Optimization ───

function swapOptimize(groups: SmartGroup[], iterations: number): void {
    for (let iter = 0; iter < iterations; iter++) {
        if (groups.length < 2) return;

        // 隨機選兩桌
        const gi = Math.floor(Math.random() * groups.length);
        let gj = Math.floor(Math.random() * groups.length);
        while (gj === gi) {
            gj = Math.floor(Math.random() * groups.length);
        }

        const groupA = groups[gi];
        const groupB = groups[gj];
        if (groupA.members.length === 0 || groupB.members.length === 0)
            continue;

        // 隨機選各桌一人
        const ai = Math.floor(Math.random() * groupA.members.length);
        const bi = Math.floor(Math.random() * groupB.members.length);

        // 計算交換前的分數
        const beforeScore =
            calculateGroupScore(groupA.members) +
            calculateGroupScore(groupB.members);

        // 嘗試交換
        const temp = groupA.members[ai];
        groupA.members[ai] = groupB.members[bi];
        groupB.members[bi] = temp;

        // 計算交換後的分數
        const afterScore =
            calculateGroupScore(groupA.members) +
            calculateGroupScore(groupB.members);

        // 如果沒有改善 → 換回來
        if (afterScore <= beforeScore) {
            const temp2 = groupA.members[ai];
            groupA.members[ai] = groupB.members[bi];
            groupB.members[bi] = temp2;
        }
    }
}

// ─── Utilities ───

function shuffle<T>(arr: T[]): void {
    for (let i = arr.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [arr[i], arr[j]] = [arr[j], arr[i]];
    }
}

// ────────────────────────────────────────────────────────
// Helpers
// ────────────────────────────────────────────────────────

function getNextThursday(from: Date): Date {
    const d = new Date(from);
    const day = d.getDay();
    // 0=Sun, 4=Thu
    const diff = (4 - day + 7) % 7 || 7; // if today is Thu, go to next Thu
    d.setDate(d.getDate() + diff);
    return d;
}

/**
 * 人數不足 → 取消活動 + 通知報名者
 */
async function handleInsufficientUsers(
    eventId: string,
    userIds: string[]
): Promise<void> {
    console.log(
        `[processWeeklyGrouping] Event ${eventId} cancelled: only ${userIds.length} users`
    );

    // 更新活動狀態
    await db.collection("dinner_events").doc(eventId).update({
        status: "cancelled",
    });

    // 推播通知
    const userDocs = await Promise.all(
        userIds.map((uid) => db.collection("users").doc(uid).get())
    );

    const tokens = userDocs
        .map((doc) => doc.data()?.fcmToken)
        .filter((t): t is string => !!t);

    if (tokens.length === 0) return;

    await admin.messaging().sendEachForMulticast({
        notification: {
            title: "📢 本週晚餐取消通知",
            body: "因報名人數不足，本週四的晚餐活動暫停。歡迎報名下週場次！",
        },
        data: {
            type: "event_cancelled",
            eventId: eventId,
        },
        tokens: tokens,
    });
}

/**
 * 分桌完成 → 通知所有報名者
 */
async function notifyGroupedUsers(
    userIds: string[],
    eventDate: admin.firestore.Timestamp
): Promise<void> {
    const userDocs = await Promise.all(
        userIds.map((uid) => db.collection("users").doc(uid).get())
    );

    const tokens = userDocs
        .map((doc) => doc.data()?.fcmToken)
        .filter((t): t is string => !!t);

    if (tokens.length === 0) return;

    const dateStr = eventDate.toDate().toLocaleDateString("zh-TW", {
        month: "long",
        day: "numeric",
        weekday: "long",
    });

    await admin.messaging().sendEachForMulticast({
        notification: {
            title: "🍽️ 晚餐已確認！",
            body: `${dateStr}的晚餐分組完成，倒數開始！餐廳地點將於活動當天揭曉。`,
        },
        data: {
            type: "event_confirmed",
        },
        apns: {
            payload: {
                aps: {
                    badge: 1,
                    sound: "default",
                },
            },
        },
        tokens: tokens,
    });
}
