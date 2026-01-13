
// Helper function to replicate Dart's String.hashCode
export function getHashCode(str: string): number {
    let hash = 0;
    if (str.length === 0) return hash;
    for (let i = 0; i < str.length; i++) {
        const char = str.charCodeAt(i);
        hash = ((hash << 5) - hash) + char;
        hash |= 0; // Convert to 32bit integer
    }
    return hash;
}

export enum ExperimentGroup {
    Control = "control", // Group A (Default)
    Variant = "variant", // Group B (Experimental)
}

export enum NotificationType {
    Match = "match",
    Message = "message",
    Event = "event",
    Rating = "rating",
    System = "system",
}

export interface NotificationContent {
    title: string;
    body: string;
}

/**
 * Assigns a user to an experiment group based on their user ID.
 * This uses a deterministic hash so the user always stays in the same group.
 */
export function getExperimentGroup(userId: string): ExperimentGroup {
    const hash = getHashCode(userId);
    return hash % 2 === 0 ? ExperimentGroup.Control : ExperimentGroup.Variant;
}

/**
 * Returns the notification content (title and body) for a given user and notification type.
 *
 * @param userId The ID of the user receiving the notification.
 * @param type The type of notification.
 * @param params Optional parameters for dynamic content (e.g., 'partnerName', 'senderName', 'daysLeft').
 */
export function getNotificationContent(
    userId: string,
    type: NotificationType | string,
    params?: { [key: string]: any }
): NotificationContent {
    const group = getExperimentGroup(userId);
    const isVariant = group === ExperimentGroup.Variant;
    const partnerName = params?.partnerName || '有人';
    const senderName = params?.senderName || '有人';
    const eventTitle = params?.eventTitle || '活動';
    const daysLeft = params?.daysLeft;

    // Convert string type to enum if necessary
    let notificationType = type;
    if (typeof type === 'string') {
        // Simple mapping, defaulting to System if not found
        switch (type) {
            case 'match': notificationType = NotificationType.Match; break;
            case 'message': notificationType = NotificationType.Message; break;
            case 'event': notificationType = NotificationType.Event; break;
            case 'rating': notificationType = NotificationType.Rating; break;
            default: notificationType = NotificationType.System; break;
        }
    }

    switch (notificationType) {
        case NotificationType.Match:
            if (isVariant) {
                return {
                    title: '配對成功！🎉',
                    body: `你與 ${partnerName} 配對成功！現在就去打個招呼吧！👋`
                };
            } else {
                return {
                    title: '新配對',
                    body: `你與 ${partnerName} 配對成功。`
                };
            }

        case NotificationType.Message:
            if (isVariant) {
                return {
                    title: '新訊息 💬',
                    body: `${senderName} 傳送了一則訊息給你。別讓對方等太久喔！`
                };
            } else {
                return {
                    title: '新訊息',
                    body: `${senderName} 傳送了一則訊息給你。`
                };
            }

        case NotificationType.Event:
            if (daysLeft !== undefined && daysLeft !== null) {
                if (isVariant) {
                    return {
                        title: '活動提醒 🍽️',
                        body: `準備好了嗎？距離「${eventTitle}」還有 ${daysLeft} 天！😋`
                    };
                } else {
                    return {
                        title: '活動提醒',
                        body: `您即將參加的活動「${eventTitle}」還有 ${daysLeft} 天。`
                    };
                }
            }

            if (isVariant) {
                return {
                    title: '活動更新 📅',
                    body: `快來查看「${eventTitle}」的最新動態！`
                };
            } else {
                return {
                    title: '活動更新',
                    body: `您的活動「${eventTitle}」有新的動態。`
                };
            }

        case NotificationType.Rating:
            if (isVariant) {
                return {
                    title: '體驗如何？⭐',
                    body: '為您的體驗評分，幫助我們做得更好！📝'
                };
            } else {
                return {
                    title: '評分您的體驗',
                    body: '請為您最近的體驗進行評分。'
                };
            }

        case NotificationType.System:
        default:
            const message = params?.message || '您有一則新通知。';
            return {
                title: '系統通知',
                body: message
            };
    }
}
