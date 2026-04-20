/// 通知文案 A/B 測試配置
/// 用於測試不同通知文案對用戶參與度的影響

export type NotificationGroup = 'A' | 'B';

export interface NotificationCopyVariant {
    variantId: string;
    title: string;
    body: string;
    emoji?: string;
}

export interface NotificationCopyTest {
    testId: string;
    notificationType: string;
    variants: NotificationCopyVariant[];
    defaultVariantId: string;
    groupVariants: Record<NotificationGroup, string>;
}

/**
 * 根據 User ID 獲取分組 (A/B)
 * 使用簡單的哈希算法保證同一個用戶總是分到同一組
 */
export function getUserGroup(userId: string): NotificationGroup {
    let hash = 0;
    for (let i = 0; i < userId.length; i++) {
        hash = ((hash << 5) - hash) + userId.charCodeAt(i);
        hash |= 0; // Convert to 32bit integer
    }
    return Math.abs(hash) % 2 === 0 ? 'A' : 'B';
}

// A/B 測試: 配對成功通知
export const matchSuccessTest: NotificationCopyTest = {
    testId: 'match_success_copy_v1',
    notificationType: 'match_success',
    defaultVariantId: 'control',
    groupVariants: {
        'A': 'control',
        'B': 'friendly'
    },
    variants: [
        {
            variantId: 'control',
            title: '配對成功!',
            body: '你與 {userName} 配對成功了',
            emoji: '🎉',
        },
        {
            variantId: 'friendly',
            title: '找到新朋友啦!',
            body: '{userName} 也喜歡你！快去打個招呼吧',
            emoji: '💕',
        },
        {
            variantId: 'urgent',
            title: '別錯過這個緣分!',
            body: '你與 {userName} 互相喜歡，現在就開始聊天吧',
            emoji: '✨',
        },
    ],
};

// A/B 測試: 新訊息通知
export const newMessageTest: NotificationCopyTest = {
    testId: 'new_message_copy_v1',
    notificationType: 'new_message',
    defaultVariantId: 'control',
    groupVariants: {
        'A': 'control',
        'B': 'engaging'
    },
    variants: [
        {
            variantId: 'control',
            title: '{userName} 傳來訊息',
            body: '{messagePreview}',
        },
        {
            variantId: 'casual',
            title: '{userName}',
            body: '「{messagePreview}」',
        },
        {
            variantId: 'engaging',
            title: '{userName} 想和你聊聊',
            body: '{messagePreview}',
            emoji: '💬',
        },
    ],
};

// A/B 測試: 活動提醒通知
export const eventReminderTest: NotificationCopyTest = {
    testId: 'event_reminder_copy_v1',
    notificationType: 'event_reminder',
    defaultVariantId: 'control',
    groupVariants: {
        'A': 'control',
        'B': 'countdown'
    },
    variants: [
        {
            variantId: 'control',
            title: '活動提醒',
            body: '{eventName} 將於 {time} 開始',
            emoji: '📅',
        },
        {
            variantId: 'countdown',
            title: '倒數計時!',
            body: '{eventName} 還有 {timeLeft} 就要開始了',
            emoji: '⏰',
        },
        {
            variantId: 'motivating',
            title: '準備好了嗎?',
            body: '{eventName} 即將開始，期待與你見面!',
            emoji: '🌟',
        },
    ],
};

// A/B 測試: 無活動提示
export const inactivityTest: NotificationCopyTest = {
    testId: 'inactivity_copy_v1',
    notificationType: 'inactivity_reminder',
    defaultVariantId: 'control',
    groupVariants: {
        'A': 'control',
        'B': 'curious'
    },
    variants: [
        {
            variantId: 'control',
            title: '好久不見',
            body: '有新的朋友在等著認識你',
        },
        {
            variantId: 'curious',
            title: '你錯過了什麼?',
            body: '上來看看有誰對你感興趣吧',
            emoji: '👀',
        },
        {
            variantId: 'fomo',
            title: '有 {count} 個人喜歡了你!',
            body: '快來看看是誰吧',
            emoji: '💝',
        },
    ],
};

// 所有測試配置
export const allNotificationTests: NotificationCopyTest[] = [
    matchSuccessTest,
    newMessageTest,
    eventReminderTest,
    inactivityTest,
];

/**
 * 根據用戶分配的變體獲取通知文案
 * @param testId 測試 ID
 * @param variantId 變體 ID
 * @param params 文案替換參數
 */
export function getNotificationCopy(
    testId: string,
    variantId: string,
    params: Record<string, string>
): { title: string; body: string } {
    const test = allNotificationTests.find((t) => t.testId === testId);
    if (!test) {
        return { title: 'Notification', body: '' };
    }

    const variant = test.variants.find((v) => v.variantId === variantId) ||
        test.variants.find((v) => v.variantId === test.defaultVariantId);

    if (!variant) {
        return { title: 'Notification', body: '' };
    }

    let title = variant.title;
    let body = variant.body;

    // 替換參數
    for (const [key, value] of Object.entries(params)) {
        title = title.replace(`{${key}}`, value);
        body = body.replace(`{${key}}`, value);
    }

    // 添加 emoji
    if (variant.emoji) {
        title = `${variant.emoji} ${title}`;
    }

    return { title, body };
}

/**
 * 根據用戶分組自動獲取通知文案
 * @param testId 測試 ID
 * @param userId 用戶 ID
 * @param params 文案替換參數
 */
export function getNotificationContentForUser(
    testId: string,
    userId: string,
    params: Record<string, string>
): { title: string; body: string; variantId: string; group: NotificationGroup } {
    const group = getUserGroup(userId);
    const test = allNotificationTests.find((t) => t.testId === testId);

    // 如果找不到測試配置，默認使用 control 變體或空
    if (!test) {
        return { ...getNotificationCopy(testId, 'control', params), variantId: 'control', group };
    }

    const variantId = test.groupVariants[group] || test.defaultVariantId;
    const content = getNotificationCopy(testId, variantId, params);

    return {
        ...content,
        variantId,
        group
    };
}
