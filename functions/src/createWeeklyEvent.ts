import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const db = admin.firestore();

// ────────────────────────────────────────────────────────
// createWeeklyEvent: 每週二 00:00
// 自動建立當週四的 DinnerEvent（MVP 僅信義區）
// ────────────────────────────────────────────────────────

export const createWeeklyEvent = functions.pubsub
    .schedule("every tuesday 00:00")
    .timeZone("Asia/Taipei")
    .onRun(async () => {
        console.log("[createWeeklyEvent] Creating weekly dinner event...");

        // 計算本週四日期
        const now = new Date();
        const day = now.getDay(); // 2 = Tuesday
        const daysUntilThursday = (4 - day + 7) % 7;
        const thursday = new Date(now);
        thursday.setDate(now.getDate() + daysUntilThursday);
        thursday.setHours(19, 0, 0, 0); // 19:00 晚餐

        // 報名截止時間：週二中午 12:00
        const signupDeadline = new Date(now);
        signupDeadline.setHours(12, 0, 0, 0);

        // 檢查是否已經建立過本週的活動
        const thursdayStart = new Date(thursday);
        thursdayStart.setHours(0, 0, 0, 0);
        const thursdayEnd = new Date(thursday);
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

        // MVP：只建一個台北市信義區的晚餐活動
        await db.collection("dinner_events").add({
            eventDate: admin.firestore.Timestamp.fromDate(thursday),
            signupDeadline: admin.firestore.Timestamp.fromDate(signupDeadline),
            city: "台北市",
            status: "open",
            signedUpUsers: [],
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        console.log(
            `[createWeeklyEvent] Created event for ${thursday.toISOString()}`
        );
    });
