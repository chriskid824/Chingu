import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const db = admin.firestore();

/**
 * bookWithValidation — 伺服器端報名驗證
 *
 * 安全流程：
 * 1. 驗證用戶身份（Firebase Auth）
 * 2. 檢查訂閱狀態（伺服器端讀取，防篡改）
 * 3. 原子操作：報名 + 消耗票券（Transaction）
 *
 * 客戶端不再直接操作 subscriptions collection
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

    // 2. Transaction：原子操作（讀取訂閱 → 驗證 → 報名 → 消耗票券）
    return db.runTransaction(async (transaction) => {
        // 2a. 讀取訂閱狀態（伺服器端，無法被客戶端篡改）
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

        // 2b. 驗證是否有資格報名
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

        // 2c. 查找或建立活動
        const eventDate = new Date(date);
        const startOfDay = new Date(eventDate);
        startOfDay.setHours(0, 0, 0, 0);
        const endOfDay = new Date(eventDate);
        endOfDay.setHours(23, 59, 59, 999);

        const eventsQuery = await db
            .collection("dinner_events")
            .where("city", "==", city)
            .where("eventDate", ">=", admin.firestore.Timestamp.fromDate(startOfDay))
            .where("eventDate", "<=", admin.firestore.Timestamp.fromDate(endOfDay))
            .where("status", "==", "open")
            .limit(1)
            .get();

        let eventId: string;

        if (!eventsQuery.empty) {
            // 加入現有活動
            eventId = eventsQuery.docs[0].id;
            const eventRef = db.collection("dinner_events").doc(eventId);

            // 檢查是否已報名
            const eventData = eventsQuery.docs[0].data();
            const signedUp = eventData.signedUpUsers || [];
            if (signedUp.includes(userId)) {
                throw new functions.https.HttpsError(
                    "already-exists",
                    "您已報名此活動"
                );
            }

            transaction.update(eventRef, {
                signedUpUsers: admin.firestore.FieldValue.arrayUnion(userId),
            });
        } else {
            // 建立新活動
            eventId = db.collection("dinner_events").doc().id;
            const eventRef = db.collection("dinner_events").doc(eventId);
            const eventDateTime = new Date(date);
            eventDateTime.setHours(19, 0, 0, 0);

            transaction.set(eventRef, {
                id: eventId,
                eventDate: admin.firestore.Timestamp.fromDate(eventDateTime),
                signupDeadline: admin.firestore.Timestamp.fromDate(
                    new Date(eventDateTime.getTime() - 24 * 60 * 60 * 1000)
                ),
                city,
                signedUpUsers: [userId],
                status: "open",
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        }

        // 2d. 消耗票券（原子操作，報名和消耗同時完成）
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
