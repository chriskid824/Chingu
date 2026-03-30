/**
 * Firebase Cloud Functions Entry Point
 *
 * Chingu — 盲盒式 6 人晚餐社交 App
 * 週四晚餐時間軸排程
 */

import * as admin from "firebase-admin";
admin.initializeApp();

// Broadcast notifications (admin)
export { sendBroadcast } from "./sendBroadcast";

// Push notification triggers (automatic)
export { onNewChatMessage, onMutualMatch } from "./pushNotifications";

// Weekly dinner grouping scheduler (週二 12:00)
export { processWeeklyGrouping } from "./weeklyScheduler";

// Companion reveal (週二 18:00)
export { revealCompanions } from "./revealCompanions";

// Weekly event auto-creation (週二 00:00)
export { createWeeklyEvent } from "./createWeeklyEvent";

// Scheduled notifications & lifecycle
export {
    sendSignupReminder,        // 週二 08:00 報名提醒
    revealRestaurants,         // 週三 17:00 餐廳揭曉 + 建立群組聊天
    sendDinnerReminder,        // 週四 18:00 今晚見
    unlockPhotos,              // 週四 19:00 照片解鎖
    completeEvents,            // 週四 22:00 活動完成
    sendReviewReminder,        // 週五 10:00 評價提醒
    sendReviewUrgentReminder,  // 週日 10:00 評價截止提醒
    autoSkipReviews,           // 週一 10:00 自動跳過逾期評價
} from "./scheduledNotifications";

// Server-side booking validation
export { bookWithValidation } from "./bookWithValidation";
