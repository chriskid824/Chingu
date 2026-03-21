/**
 * Firebase Cloud Functions Entry Point
 * 
 * This file exports all Cloud Functions for the Chingu app.
 */

import * as admin from "firebase-admin";
admin.initializeApp();

// Broadcast notifications (admin)
export { sendBroadcast } from "./sendBroadcast";

// Push notification triggers (automatic)
export { onNewChatMessage, onMutualMatch } from "./pushNotifications";

// Weekly dinner grouping scheduler
export { processWeeklyGrouping } from "./weeklyScheduler";

// Companion reveal (Wednesday 10:00)
export { revealCompanions } from "./revealCompanions";

// Weekly event auto-creation (Monday 09:00)
export { createWeeklyEvent } from "./createWeeklyEvent";

// Scheduled notifications (reminders)
export {
    sendSignupReminder,
    revealRestaurants,
    sendReviewReminder,
    completeEvents,
} from "./scheduledNotifications";

// Server-side booking validation
export { bookWithValidation } from "./bookWithValidation";
