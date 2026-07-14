import * as crypto from 'crypto';

/// 通知文案 A/B 測試配置
/// 用於測試不同通知文案對用戶參與度的影響

export type ExperimentGroup = 'control' | 'variant';

export interface NotificationCopyVariant {
    variantId: ExperimentGroup;
    title: string;
    body: string;
    emoji?: string;
}

export interface NotificationCopyTest {
    testId: string;
    notificationType: string;
    variants: Record<ExperimentGroup, NotificationCopyVariant>;
}

// Helper: 根據 User ID 獲取實驗分組 (deterministic)
export function getExperimentGroup(userId: string): ExperimentGroup {
    // 使用 MD5 hash 確保跨平台/跨時間的一致性
    const hash = crypto.createHash('md5').update(userId).digest('hex');
    // 取前 8 位轉整數
    const val = parseInt(hash.substring(0, 8), 16);
    // 偶數為 control, 奇數為 variant
    return val % 2 === 0 ? 'control' : 'variant';
}

// A/B 測試: 配對成功通知
// Control: 功能性描述
// Variant: 情感連結 (Friendly)
export const matchSuccessTest: NotificationCopyTest = {
    testId: 'match_success_copy_v1',
    notificationType: 'match_success',
    variants: {
        control: {
            variantId: 'control',
            title: '配對成功!',
            body: '你與 {userName} 配對成功了',
            emoji: '🎉',
        },
        variant: {
            variantId: 'variant',
            title: '找到新朋友啦!',
            body: '{userName} 也喜歡你！快去打個招呼吧',
            emoji: '💕',
        },
    },
};

// A/B 測試: 新訊息通知
// Control: 簡潔直接
// Variant: 促進互動 (Engaging)
export const newMessageTest: NotificationCopyTest = {
    testId: 'new_message_copy_v1',
    notificationType: 'new_message',
    variants: {
        control: {
            variantId: 'control',
            title: '{userName} 傳來訊息',
            body: '{messagePreview}',
        },
        variant: {
            variantId: 'variant',
            title: '{userName} 想和你聊聊',
            body: '{messagePreview}',
            emoji: '💬',
        },
    },
};

// A/B 測試: 活動提醒通知
// Control: 資訊性
// Variant: 緊迫感/倒數 (Countdown) - 注意需提供 timeLeft 參數
export const eventReminderTest: NotificationCopyTest = {
    testId: 'event_reminder_copy_v1',
    notificationType: 'event_reminder',
    variants: {
        control: {
            variantId: 'control',
            title: '活動提醒',
            body: '{eventName} 將於 {time} 開始',
            emoji: '📅',
        },
        variant: {
            variantId: 'variant',
            title: '倒數計時!',
            body: '{eventName} 還有 {timeLeft} 就要開始了',
            emoji: '⏰',
        },
    },
};

// A/B 測試: 無活動提示
// Control: 溫和提醒
// Variant: 好奇心驅動 (Curious)
export const inactivityTest: NotificationCopyTest = {
    testId: 'inactivity_copy_v1',
    notificationType: 'inactivity_reminder',
    variants: {
        control: {
            variantId: 'control',
            title: '好久不見',
            body: '有新的朋友在等著認識你',
        },
        variant: {
            variantId: 'variant',
            title: '你錯過了什麼?',
            body: '上來看看有誰對你感興趣吧',
            emoji: '👀',
        },
    },
};

// 所有測試配置
export const allNotificationTests: NotificationCopyTest[] = [
    matchSuccessTest,
    newMessageTest,
    eventReminderTest,
    inactivityTest,
];

/**
 * 根據用戶 ID 自動選擇並獲取通知文案
 * @param testId 測試 ID
 * @param userId 用戶 ID
 * @param params 文案替換參數
 */
export function getUserNotificationCopy(
    testId: string,
    userId: string,
    params: Record<string, string>
): { title: string; body: string; experimentGroup: ExperimentGroup } {
    const test = allNotificationTests.find((t) => t.testId === testId);

    // 如果找不到測試，回傳預設空值 (應避免發生)
    if (!test) {
        return { title: 'Notification', body: '', experimentGroup: 'control' };
    }

    const group = getExperimentGroup(userId);
    const variant = test.variants[group];

    let title = variant.title;
    let body = variant.body;

    // 替換參數
    for (const [key, value] of Object.entries(params)) {
        // 全域替換
        title = title.split(`{${key}}`).join(value);
        body = body.split(`{${key}}`).join(value);
    }

    // 添加 emoji
    if (variant.emoji) {
        title = `${variant.emoji} ${title}`;
    }

    return { title, body, experimentGroup: group };
}

// 保留舊的獲取方法以兼容舊代碼 (如果有的話)，但建議改用 getUserNotificationCopy
export function getNotificationCopy(
    testId: string,
    variantId: string, // 這裡的 variantId 實際上可能傳入 'control' 或 'variant'
    params: Record<string, string>
): { title: string; body: string } {
     const test = allNotificationTests.find((t) => t.testId === testId);
    if (!test) {
        return { title: 'Notification', body: '' };
    }

    // 嘗試匹配
    let variant = (test.variants as any)[variantId];
    if (!variant) {
        variant = test.variants.control;
    }

    let title = variant.title;
    let body = variant.body;

    for (const [key, value] of Object.entries(params)) {
        title = title.split(`{${key}}`).join(value);
        body = body.split(`{${key}}`).join(value);
    }

    if (variant.emoji) {
        title = `${variant.emoji} ${title}`;
    }

    return { title, body };
}
