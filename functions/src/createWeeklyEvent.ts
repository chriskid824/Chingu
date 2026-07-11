import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {
    nextThursdayDinnerUtc,
    signupDeadlineUtcFor,
    taipeiDayWindowUtc,
    taipeiDateString,
} from "./taipeiTime";

const db = admin.firestore();

// ────────────────────────────────────────────────────────
// createWeeklyEvent: 每週二 00:00(台北)
// 自動建立當週四的 DinnerEvent(MVP 僅信義區)
// 注意:容器時區是 UTC,牆鐘計算一律走 taipeiTime
// ────────────────────────────────────────────────────────

export const createWeeklyEvent = functions.pubsub
    .schedule("every tuesday 00:00")
    .timeZone("Asia/Taipei")
    .onRun(async () => {
        console.log("[createWeeklyEvent] Creating weekly dinner event...");

        const thursday = nextThursdayDinnerUtc(new Date());
        const signupDeadline = signupDeadlineUtcFor(thursday);
        const { start: thursdayStart, end: thursdayEnd } =
            taipeiDayWindowUtc(thursday);

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

        // 確定性 doc id:同日重跑不會重複建立
        const eventId = `dinner_${taipeiDateString(thursday)}_台北市`;
        await db.collection("dinner_events").doc(eventId).set({
            id: eventId,
            eventDate: admin.firestore.Timestamp.fromDate(thursday),
            signupDeadline: admin.firestore.Timestamp.fromDate(signupDeadline),
            city: "台北市",
            status: "open",
            signedUpUsers: [],
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        console.log(
            `[createWeeklyEvent] Created event ${eventId} for ${thursday.toISOString()}`
        );
    });
