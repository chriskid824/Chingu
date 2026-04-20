import * as crypto from 'crypto';

/// 通知文案 A/B 測試配置
/// 用於測試不同通知文案對用戶參與度的影響
export interface NotificationCopyVariant {
    variantId: string;
    title: string;
    body: string;
    emoji?: string;
    weight?: number; // 0-100 percentage
}

export interface NotificationCopyTest {
    testId: string;
    notificationType: string;
    variants: NotificationCopyVariant[];
    defaultVariantId: string;
}

// A/B 測試: 配對成功通知
export const matchSuccessTest: NotificationCopyTest = {
    testId: 'match_success_copy_v1',
    notificationType: 'match_success',
    defaultVariantId: 'control',
    variants: [
        {
            variantId: 'control',
            title: '配對成功!',
            body: '你與 {userName} 配對成功了',
            emoji: '🎉',
            weight: 34,
        },
        {
            variantId: 'friendly',
            title: '找到新朋友啦!',
            body: '{userName} 也喜歡你！快去打個招呼吧',
            emoji: '💕',
            weight: 33,
        },
        {
            variantId: 'urgent',
            title: '別錯過這個緣分!',
            body: '你與 {userName} 互相喜歡，現在就開始聊天吧',
            emoji: '✨',
            weight: 33,
        },
    ],
};

// A/B 測試: 新訊息通知
export const newMessageTest: NotificationCopyTest = {
    testId: 'new_message_copy_v1',
    notificationType: 'new_message',
    defaultVariantId: 'control',
    variants: [
        {
            variantId: 'control',
            title: '{userName} 傳來訊息',
            body: '{messagePreview}',
            weight: 34,
        },
        {
            variantId: 'casual',
            title: '{userName}',
            body: '「{messagePreview}」',
            weight: 33,
        },
        {
            variantId: 'engaging',
            title: '{userName} 想和你聊聊',
            body: '{messagePreview}',
            emoji: '💬',
            weight: 33,
        },
    ],
};

// A/B 測試: 活動提醒通知
export const eventReminderTest: NotificationCopyTest = {
    testId: 'event_reminder_copy_v1',
    notificationType: 'event_reminder',
    defaultVariantId: 'control',
    variants: [
        {
            variantId: 'control',
            title: '活動提醒',
            body: '{eventName} 將於 {time} 開始',
            emoji: '📅',
            weight: 34,
        },
        {
            variantId: 'countdown',
            title: '倒數計時!',
            body: '{eventName} 還有 {timeLeft} 就要開始了',
            emoji: '⏰',
            weight: 33,
        },
        {
            variantId: 'motivating',
            title: '準備好了嗎?',
            body: '{eventName} 即將開始，期待與你見面!',
            emoji: '🌟',
            weight: 33,
        },
    ],
};

// A/B 測試: 無活動提示
export const inactivityTest: NotificationCopyTest = {
    testId: 'inactivity_copy_v1',
    notificationType: 'inactivity_reminder',
    defaultVariantId: 'control',
    variants: [
        {
            variantId: 'control',
            title: '好久不見',
            body: '有新的朋友在等著認識你',
            weight: 34,
        },
        {
            variantId: 'curious',
            title: '你錯過了什麼?',
            body: '上來看看有誰對你感興趣吧',
            emoji: '👀',
            weight: 33,
        },
        {
            variantId: 'fomo',
            title: '有 {count} 個人喜歡了你!',
            body: '快來看看是誰吧',
            emoji: '💝',
            weight: 33,
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
 * Assigns a variant to a user deterministically based on their User ID and the Test ID.
 * This ensures the user always sees the same variant for a given test.
 * @param userId The User ID
 * @param testId The Test ID
 * @returns The assigned variant ID
 */
export function assignUserVariant(userId: string, testId: string): string {
    const test = allNotificationTests.find((t) => t.testId === testId);
    if (!test) return 'control';

    // Calculate hash of userId + testId
    const hashInput = `${userId}:${testId}`;
    const hash = crypto.createHash('sha256').update(hashInput).digest('hex');
    // Take first 8 chars and convert to int for distribution
    const hashInt = parseInt(hash.substring(0, 8), 16);
    // Modulo 100 for percentage
    const value = hashInt % 100;

    let cumulativeWeight = 0;
    for (const variant of test.variants) {
        // If weight is not specified, assume equal distribution or handle gracefully.
        // Here we default to 0 if missing, though typically we should ensure weights exist.
        const weight = variant.weight || (100 / test.variants.length);
        cumulativeWeight += weight;
        if (value < cumulativeWeight) {
            return variant.variantId;
        }
    }

    return test.defaultVariantId;
}

/**
 * 獲取用戶的通知文案 (包含變體分配邏輯)
 * @param userId 用戶 ID
 * @param testId 測試 ID
 * @param params 文案替換參數
 */
export function getUserNotificationCopy(
    userId: string,
    testId: string,
    params: Record<string, string>
): { title: string; body: string; variantId: string } {
    const variantId = assignUserVariant(userId, testId);
    const copy = getNotificationCopy(testId, variantId, params);
    return { ...copy, variantId };
}

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
