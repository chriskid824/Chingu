import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const db = admin.firestore();

// ────────────────────────────────────────────────────────
// createWeeklyEvent: 每週一 09:00
// 自動建立當週四的 DinnerEvent
// ────────────────────────────────────────────────────────

export const createWeeklyEvent = functions.pubsub
    .schedule("every monday 09:00")
    .timeZone("Asia/Taipei")
    .onRun(async () => {
        console.log("[createWeeklyEvent] Creating weekly dinner event...");

        // 計算本週四日期
        const now = new Date();
        const day = now.getDay(); // 1 = Monday
        const daysUntilThursday = (4 - day + 7) % 7;
        let thursday = new Date(now);
        thursday.setDate(now.getDate() + daysUntilThursday);
        thursday.setHours(19, 0, 0, 0); // 19:00 晚餐

        // 檢查是否已經建立過本週的活動
        let thursdayStart = new Date(thursday);
        thursdayStart.setHours(0, 0, 0, 0);
        let thursdayEnd = new Date(thursday);
        thursdayEnd.setHours(23, 59, 59, 999);

        const existing = await db
            .collection("dinner_events")
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

        if (!existing.empty) {
            console.log(
                `[createWeeklyEvent] Event already exists for ${thursday.toISOString()}`
            );
            return;
        }

        // 建立各區域的晚餐活動
        const districts = ["信義區", "大安區", "中山區"];

        for (const district of districts) {
            await db.collection("dinner_events").add({
                title: `週四晚餐 - ${district}`,
                eventDate: admin.firestore.Timestamp.fromDate(thursday),
                location: district,
                city: "台北",
                status: "open",
                maxParticipants: 30, // 最多 5 桌 × 6 人
                signedUpUsers: [],
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        }

        console.log(
            `[createWeeklyEvent] Created ${districts.length} events for ${thursday.toISOString()}`
        );
    });
