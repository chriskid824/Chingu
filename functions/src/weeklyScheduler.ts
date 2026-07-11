import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { assignRestaurant } from "./restaurantAssignment";
import { nextThursdayDinnerUtc, taipeiDayWindowUtc } from "./taipeiTime";

const db = admin.firestore();

// ────────────────────────────────────────────────────────
// 破冰話題 — 從 Firestore /icebreaker_questions 動態載入
// 分 3 層級：warmup(3題) → deep(4題) → soulful(3題)
// ────────────────────────────────────────────────────────

type IcebreakerPools = Record<string, string[]>;

async function loadIcebreakerPools(): Promise<IcebreakerPools> {
    const snapshot = await db
        .collection("icebreaker_questions")
        .where("isActive", "==", true)
        .get();

    const byLevel: IcebreakerPools = { warmup: [], deep: [], soulful: [] };
    if (snapshot.empty) {
        console.warn("[loadIcebreakerPools] No icebreaker questions found in Firestore");
        return byLevel;
    }

    for (const doc of snapshot.docs) {
        const data = doc.data();
        const level = data.level || "deep";
        if (byLevel[level]) {
            byLevel[level].push(doc.id);
        }
    }
    return byLevel;
}

function pickIcebreakers(pools: IcebreakerPools): string[] {
    // 隨機抽取：warmup 3 + deep 4 + soulful 3 = 10
    const pick = (arr: string[], n: number) => {
        const shuffled = [...arr].sort(() => Math.random() - 0.5);
        return shuffled.slice(0, n);
    };

    return [
        ...pick(pools.warmup, 3),
        ...pick(pools.deep, 4),
        ...pick(pools.soulful, 3),
    ];
}

// ────────────────────────────────────────────────────────
// 每週二 12:00(台北)截止報名 + 自動分桌
// ────────────────────────────────────────────────────────

/**
 * processWeeklyGrouping
 *
 * 排程觸發：每週二 12:00 台北時間
 *
 * 流程：
 * 1. 找出本週四的所有 open 活動
 * 2. 按城市+區域 + 用餐偏好(硬性)分池
 * 3. 每 5~7 人一桌（不足 5 人不成桌，保留下週）
 * 4. 為每桌指派餐廳
 * 5. 建立 DinnerGroup（確定性 id，重跑不重複）
 * 6. 更新 DinnerEvent 狀態為 closed
 * 7. 推播通知：成桌者與未成桌者分別通知
 */
export const processWeeklyGrouping = functions.pubsub
    .schedule("every tuesday 12:00")
    .timeZone("Asia/Taipei")
    .onRun(async () => {
        console.log("[processWeeklyGrouping] Starting weekly grouping...");

        // 1. 找到本週四的活動（status = 'open'）
        //    牆鐘計算一律走 taipeiTime（容器時區是 UTC）
        const thisThursday = nextThursdayDinnerUtc(new Date());
        const { start: thursdayStart, end: thursdayEnd } =
            taipeiDayWindowUtc(thisThursday);

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

        const icebreakerPools = await loadIcebreakerPools();
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

            if (signedUpUsers.length < 5) {
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
            const missingProfileIds: string[] = [];

            for (let i = 0; i < userDocs.length; i++) {
                const userDoc = userDocs[i];
                if (!userDoc.exists) {
                    missingProfileIds.push(signedUpUsers[i]);
                    continue;
                }
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
            if (missingProfileIds.length > 0) {
                console.warn(
                    `[processWeeklyGrouping] ${missingProfileIds.length} signed-up users have no profile: ${missingProfileIds.join(",")}`
                );
            }

            // 3. 分桌（用餐偏好硬分區 + 5~7 人保證）
            const { groups, ungrouped } = createSmartGroups(
                Array.from(usersByDistrict.entries()),
                city
            );

            // 4. 為每桌建立 DinnerGroup + 指派餐廳
            //    確定性 doc id：中途失敗重跑會覆寫同一批 doc，不會重複建組
            for (let gi = 0; gi < groups.length; gi++) {
                const group = groups[gi];
                const groupId = `${eventId}_t${String(gi).padStart(2, "0")}`;
                const groupRef = db.collection("dinner_groups").doc(groupId);
                const icebreakers = pickIcebreakers(icebreakerPools);

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
                    const assigned = await assignRestaurant(
                        groupRef.id,
                        group.participantIds,
                        city,
                        group.district
                    );
                    if (!assigned) {
                        console.error(
                            `[processWeeklyGrouping] ALERT: no restaurant assigned for group ${groupId} — 需人工指定`
                        );
                    }
                } catch (error) {
                    console.error(
                        `[processWeeklyGrouping] Restaurant assignment failed for group ${groupId}:`,
                        error
                    );
                }

                totalGroups++;
            }

            // 5. 更新活動狀態
            await db.collection("dinner_events").doc(eventId).update({
                status: "closed",
                groupedUserIds: groups.flatMap((g) => g.participantIds),
                ungroupedUserIds: ungrouped,
            });

            // 6. 推播通知：只通知真正成桌的人；未成桌者另發保留通知
            await notifyGroupedUsers(
                groups.flatMap((g) => g.participantIds),
                eventData.eventDate
            );
            await notifyUngroupedUsers([...ungrouped, ...missingProfileIds]);
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
    diningPreference: string; // 'male' | 'female' | 'any' | 'no_preference'
    interests: string[];
    age: number;
    budgetRange: number;
    district: string;
}

interface GroupResult {
    participantIds: string[];
    district: string;
    kind: "same_sex" | "mixed";
}

interface GroupingOutcome {
    groups: GroupResult[];
    /** 未成桌者（同性別桌湊不滿、溢出無桌可併），保留至下週 */
    ungrouped: string[];
}

/**
 * 把 n 人切成若干 5~7 人桌。回傳每桌人數；無法納入的餘數由呼叫端處理。
 * n=8、9 無法完全分割（任何 5~7 的組合都湊不出），會留下 1~2 人餘數。
 */
function chunkSizes(n: number): { sizes: number[]; leftover: number } {
    const bad = new Set([1, 2, 3, 4, 8, 9]);
    const sizes: number[] = [];
    while (n >= 5) {
        if (n <= 7) {
            sizes.push(n);
            n = 0;
        } else {
            let take = 0;
            for (const t of [7, 6, 5]) {
                if (!bad.has(n - t)) {
                    take = t;
                    break;
                }
            }
            if (take === 0) {
                // n = 8 或 9：取一桌 7，餘 1~2 人留給呼叫端
                take = 7;
            }
            sizes.push(take);
            n -= take;
        }
    }
    return { sizes, leftover: n };
}

/**
 * 智能配對 — 用餐偏好硬分區 + 性別平衡 + 興趣相容 + 年齡/預算軟性考量
 *
 * 硬性規則（產品鐵律層級）：
 * 1. 男→男（gender=male 且 diningPreference=male）只進純男桌；女→女同理。
 *    湊不滿 5 人不硬湊、不混桌，保留至下週。
 * 2. 每桌 5~7 人，絕不超過 7。
 * 3. 其餘偏好（異性/any/no_preference）進混合池，盡量性別平衡。
 */
function createSmartGroups(
    districtEntries: [
        string,
        { uid: string; data: admin.firestore.DocumentData }[],
    ][],
    _city: string
): GroupingOutcome {
    const groups: GroupResult[] = [];
    const ungrouped: string[] = [];
    const overflow: UserProfile[] = []; // 只收混合池溢出者

    for (const [district, users] of districtEntries) {
        // 轉為 UserProfile
        const profiles: UserProfile[] = users.map((u) => ({
            uid: u.uid,
            gender: u.data.gender || "undisclosed",
            diningPreference: u.data.diningPreference || "any",
            interests: u.data.interests || [],
            age: u.data.age || 25,
            budgetRange: u.data.budgetRange ?? 1,
            district: district,
        }));

        // ── 硬分區：同性別桌池 vs 混合池 ──
        const sameSexMale = profiles.filter(
            (p) => p.gender === "male" && p.diningPreference === "male"
        );
        const sameSexFemale = profiles.filter(
            (p) => p.gender === "female" && p.diningPreference === "female"
        );
        const mixed = profiles.filter(
            (p) => !sameSexMale.includes(p) && !sameSexFemale.includes(p)
        );

        // 同性別桌：切 5~7 人桌；不足 5 或餘數 → 保留下週（不混桌）
        for (const pool of [sameSexMale, sameSexFemale]) {
            if (pool.length === 0) continue;
            shuffle(pool);
            const { sizes, leftover } = chunkSizes(pool.length);
            let idx = 0;
            for (const size of sizes) {
                groups.push({
                    participantIds: pool
                        .slice(idx, idx + size)
                        .map((p) => p.uid),
                    district,
                    kind: "same_sex",
                });
                idx += size;
            }
            for (let i = idx; i < pool.length; i++) {
                ungrouped.push(pool[i].uid);
            }
            if (leftover > 0) {
                console.log(
                    `[createSmartGroups] same-sex pool leftover ${leftover} in ${district}, carried over`
                );
            }
        }

        // 混合池：性別平衡分桌
        const males = mixed.filter((p) => p.gender === "male");
        const females = mixed.filter((p) => p.gender === "female");
        const others = mixed.filter(
            (p) => p.gender !== "male" && p.gender !== "female"
        );

        shuffle(males);
        shuffle(females);
        shuffle(others);

        const districtGroups = genderBalancedSplit(
            males,
            females,
            others,
            district
        );

        if (districtGroups.length >= 2) {
            swapOptimize(districtGroups, 50);
        }

        for (const g of districtGroups) {
            if (g.members.length >= 5 && g.members.length <= 7) {
                groups.push({
                    participantIds: g.members.map((m) => m.uid),
                    district: district,
                    kind: "mixed",
                });
            } else {
                overflow.push(...g.members);
            }
        }
    }

    // ── 溢出池處理（只含混合池成員）──
    if (overflow.length >= 5) {
        shuffle(overflow);
        const { sizes } = chunkSizes(overflow.length);
        let idx = 0;
        for (const size of sizes) {
            groups.push({
                participantIds: overflow
                    .slice(idx, idx + size)
                    .map((u) => u.uid),
                district: overflow[idx].district || "信義區",
                kind: "mixed",
            });
            idx += size;
        }
        // 餘數：塞進未滿 7 人的混合桌；沒有空位就保留下週
        for (let i = idx; i < overflow.length; i++) {
            const target = groups
                .filter(
                    (g) => g.kind === "mixed" && g.participantIds.length < 7
                )
                .sort(
                    (a, b) =>
                        a.participantIds.length - b.participantIds.length
                )[0];
            if (target) {
                target.participantIds.push(overflow[i].uid);
            } else {
                ungrouped.push(overflow[i].uid);
            }
        }
    } else if (overflow.length > 0) {
        // 不足 5 人的溢出：塞進未滿 7 的混合桌，塞不下保留下週
        for (const user of overflow) {
            const target = groups
                .filter(
                    (g) => g.kind === "mixed" && g.participantIds.length < 7
                )
                .sort(
                    (a, b) =>
                        a.participantIds.length - b.participantIds.length
                )[0];
            if (target) {
                target.participantIds.push(user.uid);
            } else {
                ungrouped.push(user.uid);
            }
        }
    }

    return { groups, ungrouped };
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

    const numTables = Math.ceil(totalPeople / 7);
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

/** FCM multicast 上限 500 token/次，一律分批送且單批失敗不中斷 */
async function sendMulticastChunked(
    tokens: string[],
    message: Omit<admin.messaging.MulticastMessage, "tokens">
): Promise<void> {
    for (let i = 0; i < tokens.length; i += 500) {
        const chunk = tokens.slice(i, i + 500);
        try {
            await admin.messaging().sendEachForMulticast({
                ...message,
                tokens: chunk,
            });
        } catch (error) {
            console.error("[sendMulticastChunked] batch failed:", error);
        }
    }
}

async function tokensForUsers(userIds: string[]): Promise<string[]> {
    if (userIds.length === 0) return [];
    const userDocs = await Promise.all(
        userIds.map((uid) => db.collection("users").doc(uid).get())
    );
    return userDocs
        .map((doc) => doc.data()?.fcmToken)
        .filter((t): t is string => !!t);
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

    const tokens = await tokensForUsers(userIds);
    if (tokens.length === 0) return;

    await sendMulticastChunked(tokens, {
        notification: {
            title: "📢 本週晚餐取消通知",
            body: "因報名人數不足，本週四的晚餐活動暫停。歡迎報名下週場次！",
        },
        data: {
            type: "event_cancelled",
            eventId: eventId,
        },
    });
}

/**
 * 分桌完成 → 只通知真正成桌的參與者
 */
async function notifyGroupedUsers(
    userIds: string[],
    eventDate: admin.firestore.Timestamp
): Promise<void> {
    const tokens = await tokensForUsers(userIds);
    if (tokens.length === 0) return;

    const dateStr = eventDate.toDate().toLocaleDateString("zh-TW", {
        month: "long",
        day: "numeric",
        weekday: "long",
        timeZone: "Asia/Taipei",
    });

    await sendMulticastChunked(tokens, {
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
    });
}

/**
 * 未成桌者（同性別桌湊不滿、溢出無位）→ 保留下週通知
 */
async function notifyUngroupedUsers(userIds: string[]): Promise<void> {
    if (userIds.length === 0) return;
    console.log(
        `[processWeeklyGrouping] ${userIds.length} users carried over to next week: ${userIds.join(",")}`
    );

    const tokens = await tokensForUsers(userIds);
    if (tokens.length === 0) return;

    await sendMulticastChunked(tokens, {
        notification: {
            title: "🌙 本週先休息一下",
            body: "正在為你尋找最合適的飯友，你的名額已保留至下週，下週優先安排！",
        },
        data: {
            type: "carried_over",
        },
    });
}
