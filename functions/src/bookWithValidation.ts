import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {
    parseTaipeiDinnerDate,
    signupDeadlineUtcFor,
    taipeiDayWindowUtc,
    taipeiDateString,
} from "./taipeiTime";

const db = admin.firestore();

/**
 * bookWithValidation — 伺服器端報名驗證
 *
 * 安全流程:
 * 1. 驗證用戶身份(Firebase Auth)
 * 2. 檢查訂閱狀態(伺服器端讀取,防篡改)
 * 3. 檢查報名截止時間(週二 12:00 台北,伺服器端強制)
 * 4. 原子操作:報名 + 消耗票券(Transaction,活動查詢也在 transaction 內)
 *
 * date 參數只取 YYYY-MM-DD,視為台北日曆日(晚餐固定 19:00 台北)
 */
export const bookWithValidation = functions.https.onCall(async (data, context) => {
    // 1. 驗證身份
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "請先登入"
        );
    }

    const userId = context.auth.uid;
    const { date, city, district } = data;

    if (!date || !city || !district) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "缺少必要參數：date, city, district"
        );
    }

    const dinnerUtc = parseTaipeiDinnerDate(date);
    if (!dinnerUtc) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "日期格式錯誤"
        );
    }

    // 2. 伺服器端截止檢查:該週週二 12:00(台北)後不可報名
    const deadline = signupDeadlineUtcFor(dinnerUtc);
    if (new Date() > deadline) {
        throw new functions.https.HttpsError(
            "deadline-exceeded",
            "本週報名已截止，下週再來吧！"
        );
    }

    // 3. Transaction:原子操作(讀取訂閱 + 活動 → 驗證 → 報名 → 消耗票券)
    return db.runTransaction(async (transaction) => {
        // 3a. 讀取訂閱狀態(伺服器端,無法被客戶端篡改)
        const subRef = db.collection("subscriptions").doc(userId);
        const subDoc = await transaction.get(subRef);

        let freeTrials = 3;
        let singleTickets = 0;
        let plan = "free";
        let expiresAt: Date | null = null;

        if (subDoc.exists) {
            const subData = subDoc.data()!;
            freeTrials = subData.freeTrialsRemaining ?? 3;
            singleTickets = subData.singleTickets ?? 0;
            plan = subData.plan ?? "free";
            expiresAt = subData.expiresAt?.toDate() ?? null;
        }

        // 3b. 驗證是否有資格報名
        const now = new Date();
        let ticketType: "free" | "single" | "subscription" | null = null;

        if (freeTrials > 0) {
            ticketType = "free";
        } else if (singleTickets > 0) {
            ticketType = "single";
        } else if (
            (plan === "monthly" || plan === "quarterly") &&
            expiresAt && expiresAt > now
        ) {
            ticketType = "subscription";
        }

        if (!ticketType) {
            throw new functions.https.HttpsError(
                "permission-denied",
                "沒有可用的票券，請先購買方案"
            );
        }

        // 3c. 查找或建立活動(查詢在 transaction 內,避免併發重複建立)
        const { start: startOfDay, end: endOfDay } = taipeiDayWindowUtc(dinnerUtc);
        const eventsQuery = db
            .collection("dinner_events")
            .where("city", "==", city)
            .where("eventDate", ">=", admin.firestore.Timestamp.fromDate(startOfDay))
            .where("eventDate", "<=", admin.firestore.Timestamp.fromDate(endOfDay))
            .limit(1);
        const eventsSnap = await transaction.get(eventsQuery);

        let eventId: string;

        if (!eventsSnap.empty) {
            const eventDoc = eventsSnap.docs[0];
            eventId = eventDoc.id;
            const eventData = eventDoc.data();

            // 已截止/已分桌的活動不可再報名,也不可另建孤兒活動
            if (eventData.status !== "open") {
                throw new functions.https.HttpsError(
                    "deadline-exceeded",
                    "本週報名已截止，下週再來吧！"
                );
            }

            const signedUp = eventData.signedUpUsers || [];
            if (signedUp.includes(userId)) {
                throw new functions.https.HttpsError(
                    "already-exists",
                    "您已報名此活動"
                );
            }

            transaction.update(eventDoc.ref, {
                signedUpUsers: admin.firestore.FieldValue.arrayUnion(userId),
            });
        } else {
            // 建立新活動(確定性 id:同日同城市不會重複建立)
            eventId = `dinner_${taipeiDateString(dinnerUtc)}_${city}`;
            const eventRef = db.collection("dinner_events").doc(eventId);

            transaction.set(eventRef, {
                id: eventId,
                eventDate: admin.firestore.Timestamp.fromDate(dinnerUtc),
                signupDeadline: admin.firestore.Timestamp.fromDate(deadline),
                city,
                signedUpUsers: [userId],
                status: "open",
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        }

        // 3d. 消耗票券(原子操作,報名和消耗同時完成)
        if (ticketType === "free") {
            transaction.set(
                subRef,
                { freeTrialsRemaining: freeTrials - 1 },
                { merge: true }
            );
        } else if (ticketType === "single") {
            transaction.set(
                subRef,
                { singleTickets: singleTickets - 1 },
                { merge: true }
            );
        }
        // subscription 不需要消耗

        return {
            success: true,
            eventId,
            ticketType,
            remaining: ticketType === "free"
                ? freeTrials - 1
                : ticketType === "single"
                    ? singleTickets - 1
                    : null,
        };
    });
});
