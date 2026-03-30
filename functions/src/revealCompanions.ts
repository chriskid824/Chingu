import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const db = admin.firestore();
const messaging = admin.messaging();

// 星座對照表（依月日）
const ZODIAC_RANGES: { sign: string; start: [number, number]; end: [number, number] }[] = [
    { sign: "水瓶座", start: [1, 20], end: [2, 18] },
    { sign: "雙魚座", start: [2, 19], end: [3, 20] },
    { sign: "牡羊座", start: [3, 21], end: [4, 19] },
    { sign: "金牛座", start: [4, 20], end: [5, 20] },
    { sign: "雙子座", start: [5, 21], end: [6, 20] },
    { sign: "巨蟹座", start: [6, 21], end: [7, 22] },
    { sign: "獅子座", start: [7, 23], end: [8, 22] },
    { sign: "處女座", start: [8, 23], end: [9, 22] },
    { sign: "天秤座", start: [9, 23], end: [10, 22] },
    { sign: "天蠍座", start: [10, 23], end: [11, 21] },
    { sign: "射手座", start: [11, 22], end: [12, 21] },
    { sign: "摩羯座", start: [12, 22], end: [1, 19] },
];

function getZodiac(birthday: Date | null, age: number | null): string {
    if (birthday) {
        const month = birthday.getMonth() + 1;
        const day = birthday.getDate();
        for (const z of ZODIAC_RANGES) {
            if (z.sign === "摩羯座") {
                if ((month === 12 && day >= 22) || (month === 1 && day <= 19)) return z.sign;
            } else {
                const [sm, sd] = z.start;
                const [em, ed] = z.end;
                if ((month === sm && day >= sd) || (month === em && day <= ed)) return z.sign;
            }
        }
    }
    // 沒有生日資料時，顯示尚未設定
    return "尚未設定 ✨";
}

// 從職稱推算產業類別
function getIndustryCategory(job: string): string {
    const categories: Record<string, string[]> = {
        "科技業": ["工程師", "軟體", "前端", "後端", "tech", "engineer", "developer", "PM", "產品"],
        "設計": ["設計", "design", "UI", "UX", "插畫", "美術"],
        "金融業": ["金融", "銀行", "投資", "會計", "財務", "finance"],
        "行銷": ["行銷", "marketing", "social media", "公關", "企劃"],
        "醫療": ["醫", "護理", "藥", "醫療", "health"],
        "教育": ["教師", "老師", "教授", "education", "教育"],
        "餐飲": ["餐飲", "廚師", "chef", "barista"],
        "法律": ["律師", "法務", "法律"],
        "藝文": ["藝術", "音樂", "演員", "創作"],
        "業務": ["業務", "sales", "經理"],
    };

    const jobLower = job.toLowerCase();
    for (const [category, keywords] of Object.entries(categories)) {
        if (keywords.some((k) => jobLower.includes(k.toLowerCase()))) {
            return category;
        }
    }
    return "其他產業";
}

// 年齡轉年齡層
function getAgeGroup(age: number): string {
    if (age < 25) return "20 代前半";
    if (age < 30) return "20 代後半";
    if (age < 35) return "30 代前半";
    if (age < 40) return "30 代後半";
    return "40+";
}

// ────────────────────────────────────────────────────────
// revealCompanions: 每週二 18:00
// 揭曉同伴匿名資訊（星座/產業/年齡段）+ 初始化出席確認
// ────────────────────────────────────────────────────────

export const revealCompanions = functions.pubsub
    .schedule("every tuesday 18:00")
    .timeZone("Asia/Taipei")
    .onRun(async () => {
        console.log("[revealCompanions] Revealing companion info...");

        // 找最近 48 小時內建立的 pending DinnerGroup
        const cutoff = new Date();
        cutoff.setHours(cutoff.getHours() - 48);

        const groups = await db
            .collection("dinner_groups")
            .where("status", "==", "pending")
            .where("createdAt", ">=", admin.firestore.Timestamp.fromDate(cutoff))
            .get();

        if (groups.empty) {
            console.log("[revealCompanions] No pending groups found");
            return;
        }

        let totalGroups = 0;
        const allTokens: string[] = [];

        for (const groupDoc of groups.docs) {
            const groupData = groupDoc.data();
            const participantIds: string[] = groupData.participantIds || [];

            // 取得所有成員資料
            const userDocs = await Promise.all(
                participantIds.map((uid) =>
                    db.collection("users").doc(uid).get()
                )
            );

            // 為每個成員建立匿名預覽卡片
            const companionPreviews: Record<string, unknown>[] = [];
            const attendanceConfirmed: Record<string, boolean> = {};

            for (const userDoc of userDocs) {
                if (!userDoc.exists) continue;
                const data = userDoc.data()!;

                const age: number = data.age ?? 25;
                const birthday = data.birthday
                    ? (data.birthday as admin.firestore.Timestamp).toDate()
                    : null;

                const interests: string[] = data.interests ?? [];
                const preview = {
                    index: companionPreviews.length, // 用序號而非 uid，保護隱私
                    zodiac: getZodiac(birthday, age),
                    industryCategory: getIndustryCategory(data.job ?? ""),
                    ageGroup: getAgeGroup(age),
                    topInterests: interests.length >= 2 ? interests.slice(0, 2) : [],
                    nationality: data.country ?? "台灣",
                };

                companionPreviews.push(preview);
                attendanceConfirmed[userDoc.id] = false;

                // 收集 FCM token
                const token = data.fcmToken;
                if (token) allTokens.push(token);
            }

            // 更新 DinnerGroup
            await groupDoc.ref.update({
                status: "info_revealed",
                companionPreviews: companionPreviews,
                attendanceConfirmed: attendanceConfirmed,
            });

            totalGroups++;
        }

        // 推播通知所有成員
        if (allTokens.length > 0) {
            const batches = chunkArray(allTokens, 500);
            for (const batch of batches) {
                await messaging.sendEachForMulticast({
                    notification: {
                        title: "👀 同桌夥伴揭曉！",
                        body: "你的晚餐同伴資訊已解鎖，快來看看他們是什麼星座！記得確認出席 ✅",
                    },
                    data: {
                        type: "companions_revealed",
                    },
                    apns: {
                        payload: {
                            aps: { badge: 1, sound: "default" },
                        },
                    },
                    android: {
                        notification: {
                            channelId: "chingu_events",
                        },
                    },
                    tokens: batch,
                });
            }
        }

        console.log(
            `[revealCompanions] Revealed ${totalGroups} groups, notified ${allTokens.length} users`
        );
    });

// Helper
function chunkArray<T>(array: T[], chunkSize: number): T[][] {
    const chunks: T[][] = [];
    for (let i = 0; i < array.length; i += chunkSize) {
        chunks.push(array.slice(i, i + chunkSize));
    }
    return chunks;
}
