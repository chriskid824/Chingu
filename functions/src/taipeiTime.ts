// 台北時區(UTC+8)換算工具。
// Cloud Functions 容器一律跑 UTC,任何「牆鐘時間」(週四 19:00、週二 12:00…)
// 都必須經過這裡換算,禁止直接對 new Date() 用 setHours()/getDay()。

const TAIPEI_OFFSET_MS = 8 * 60 * 60 * 1000;

/**
 * 把 UTC 時刻平移成「以 UTC 欄位承載的台北牆鐘」。
 * 回傳值只能用 getUTC*() 讀取(getUTCDay/getUTCDate…),不可再存回 Firestore。
 */
export function toTaipeiWallClock(at: Date = new Date()): Date {
    return new Date(at.getTime() + TAIPEI_OFFSET_MS);
}

/** 以台北牆鐘(年, 月0起, 日, 時, 分)建立真正的 UTC Date(可存 Firestore)。 */
export function taipeiWallClockToUtc(
    year: number,
    month: number,
    day: number,
    hour = 0,
    minute = 0
): Date {
    return new Date(Date.UTC(year, month, day, hour, minute) - TAIPEI_OFFSET_MS);
}

/** 從某 UTC 時刻起算,「台北時間的下一個(含當日)週四 19:00」對應的 UTC Date。 */
export function nextThursdayDinnerUtc(from: Date = new Date()): Date {
    const tp = toTaipeiWallClock(from);
    const daysUntilThursday = (4 - tp.getUTCDay() + 7) % 7;
    return taipeiWallClockToUtc(
        tp.getUTCFullYear(),
        tp.getUTCMonth(),
        tp.getUTCDate() + daysUntilThursday,
        19,
        0
    );
}

/** 某 UTC 時刻在台北時區的當日 [00:00:00.000, 23:59:59.999] 視窗(UTC Date pair)。 */
export function taipeiDayWindowUtc(at: Date): { start: Date; end: Date } {
    const tp = toTaipeiWallClock(at);
    const start = taipeiWallClockToUtc(
        tp.getUTCFullYear(),
        tp.getUTCMonth(),
        tp.getUTCDate(),
        0,
        0
    );
    return { start, end: new Date(start.getTime() + 24 * 60 * 60 * 1000 - 1) };
}

/**
 * 解析 client 傳來的日期字串(只取 YYYY-MM-DD,視為台北日曆日),
 * 回傳該日台北 19:00 晚餐時刻的 UTC Date;格式不合回傳 null。
 */
export function parseTaipeiDinnerDate(raw: string): Date | null {
    const m = /^(\d{4})-(\d{2})-(\d{2})/.exec(String(raw));
    if (!m) return null;
    return taipeiWallClockToUtc(Number(m[1]), Number(m[2]) - 1, Number(m[3]), 19, 0);
}

/** 該晚餐日(台北週四)對應的報名截止:同週週二 12:00 台北 → UTC Date。 */
export function signupDeadlineUtcFor(dinnerUtc: Date): Date {
    const tp = toTaipeiWallClock(dinnerUtc);
    return taipeiWallClockToUtc(
        tp.getUTCFullYear(),
        tp.getUTCMonth(),
        tp.getUTCDate() - 2,
        12,
        0
    );
}

/** 台北日曆日字串 YYYY-MM-DD(給確定性 doc id 用)。 */
export function taipeiDateString(at: Date): string {
    const tp = toTaipeiWallClock(at);
    const mm = String(tp.getUTCMonth() + 1).padStart(2, "0");
    const dd = String(tp.getUTCDate()).padStart(2, "0");
    return `${tp.getUTCFullYear()}-${mm}-${dd}`;
}
