/**
 * onMutualMatch 端到端整合測試
 *
 * 需要 Firebase Emulator 正在運行：
 *   firebase emulators:start --only firestore,functions --project demo-chingu
 *
 * 驗證 onMutualMatch Cloud Function trigger 的核心行為：
 *   1. 雙向 like → 建立 chat_room (確定性 ID)
 *   2. 單向 like → 不建立
 *   3. 重複寫入 → 不會建立第二份 chat_room
 *   4. 雙方 totalMatches 都各自 +1 (batch 原子性)
 *   5. like + dislike → 不構成 Match
 */

import * as admin from "firebase-admin";

process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";
process.env.GCLOUD_PROJECT = "demo-chingu";

if (!admin.apps.length) {
    admin.initializeApp({projectId: "demo-chingu"});
}

const db = admin.firestore();

// Firestore trigger 是非同步，寫入後需等 CF 處理完
const TRIGGER_WAIT_MS = 4000;
const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

// 每次測試用唯一 ID，避免跨測試干擾
const ts = Date.now();
const EVENT_ID = `evt_${ts}`;
const GROUP_ID = `grp_${ts}`;
const USER_A = `userA_${ts}`;
const USER_B = `userB_${ts}`;
const USER_C = `userC_${ts}`;

function chatRoomId(userX: string, userY: string): string {
    const sorted = [userX, userY].sort();
    return `match_${sorted[0]}_${sorted[1]}_${EVENT_ID}`;
}

async function getChatRoom(
    userX: string,
    userY: string
): Promise<FirebaseFirestore.DocumentData | null> {
    const doc = await db.collection("chat_rooms").doc(chatRoomId(userX, userY)).get();
    return doc.exists ? doc.data()! : null;
}

async function getUserMatches(uid: string): Promise<number> {
    const doc = await db.collection("users").doc(uid).get();
    return doc.data()?.totalMatches ?? 0;
}

// ──────────────────────────────────────────────────────────────
// Setup / Teardown
// ──────────────────────────────────────────────────────────────

beforeAll(async () => {
    // 確認 emulator 存活
    try {
        await db.collection("health_check").doc("ping").set({ts: Date.now()});
        await db.collection("health_check").doc("ping").delete();
    } catch {
        throw new Error(
            "Firestore Emulator 無法連線 — 請確認 firebase emulators:start 已啟動"
        );
    }

    await db.collection("users").doc(USER_A).set({
        name: "Alice", fcmToken: "fake-token-A", totalMatches: 0,
    });
    await db.collection("users").doc(USER_B).set({
        name: "Bob", fcmToken: "fake-token-B", totalMatches: 0,
    });
    await db.collection("users").doc(USER_C).set({
        name: "Carol", fcmToken: "fake-token-C", totalMatches: 0,
    });
});

// ──────────────────────────────────────────────────────────────
// Tests
// ──────────────────────────────────────────────────────────────

jest.setTimeout(30000);

describe("onMutualMatch", () => {
    test("單向 like 不觸發 Match — 不建立 chat_room", async () => {
        await db.collection("dinner_reviews").add({
            reviewerId: USER_A,
            revieweeId: USER_B,
            groupId: GROUP_ID,
            eventId: EVENT_ID,
            result: "like",
        });

        await sleep(TRIGGER_WAIT_MS);

        const room = await getChatRoom(USER_A, USER_B);
        expect(room).toBeNull();
    });

    test("雙向 like 建立 chat_room — 確定性 ID + batch totalMatches", async () => {
        await db.collection("dinner_reviews").add({
            reviewerId: USER_B,
            revieweeId: USER_A,
            groupId: GROUP_ID,
            eventId: EVENT_ID,
            result: "like",
        });

        await sleep(TRIGGER_WAIT_MS);

        const room = await getChatRoom(USER_A, USER_B);
        expect(room).not.toBeNull();
        expect(room!.type).toBe("direct");
        expect(room!.participantIds).toContain(USER_A);
        expect(room!.participantIds).toContain(USER_B);
        expect(room!.dinnerEventId).toBe(EVENT_ID);

        // batch 原子性：雙方 totalMatches 各 +1
        expect(await getUserMatches(USER_A)).toBe(1);
        expect(await getUserMatches(USER_B)).toBe(1);

        // 系統歡迎訊息
        const messages = await db
            .collection("chat_rooms")
            .doc(chatRoomId(USER_A, USER_B))
            .collection("messages")
            .get();
        expect(messages.size).toBeGreaterThanOrEqual(1);
    });

    test("重複 mutual review 不建立第二份 chat_room (idempotent)", async () => {
        // 再寫一次 A→B like (模擬 race condition retry)
        await db.collection("dinner_reviews").add({
            reviewerId: USER_A,
            revieweeId: USER_B,
            groupId: GROUP_ID,
            eventId: EVENT_ID,
            result: "like",
        });

        await sleep(TRIGGER_WAIT_MS);

        const snap = await db
            .collection("chat_rooms")
            .where("participantIds", "array-contains", USER_A)
            .get();

        const matchingRooms = snap.docs.filter((d) => {
            const ids: string[] = d.data().participantIds || [];
            return ids.includes(USER_A) && ids.includes(USER_B);
        });

        expect(matchingRooms).toHaveLength(1);
    });

    test("like + dislike 不構成 Match", async () => {
        await db.collection("dinner_reviews").add({
            reviewerId: USER_A,
            revieweeId: USER_C,
            groupId: GROUP_ID,
            eventId: EVENT_ID,
            result: "like",
        });

        await db.collection("dinner_reviews").add({
            reviewerId: USER_C,
            revieweeId: USER_A,
            groupId: GROUP_ID,
            eventId: EVENT_ID,
            result: "dislike",
        });

        await sleep(TRIGGER_WAIT_MS);

        const room = await getChatRoom(USER_A, USER_C);
        expect(room).toBeNull();
    });
});
