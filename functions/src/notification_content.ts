import * as admin from "firebase-admin";

/// 通知文案 A/B 測試配置
/// 用於測試不同通知文案對用戶參與度的影響
export interface NotificationCopyVariant {
    variantId: string;
    title: string;
    body: string;
    emoji?: string;
    weight?: number; // 0-100
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
 * 獲取或分配用戶在特定測試中的變體
 * @param userId 用戶 ID
 * @param testId 測試 ID
 */
export async function getUserVariant(userId: string, testId: string): Promise<string> {
    try {
        const db = admin.firestore();
        const userVariantRef = db.collection('users').doc(userId).collection('ab_test_variants').doc(testId);

        const doc = await userVariantRef.get();
        if (doc.exists) {
            return doc.data()?.variant as string;
        }

        // 分配新變體
        const test = allNotificationTests.find(t => t.testId === testId);
        if (!test) return 'control';

        // 簡單權重分配
        const random = Math.random() * 100;
        let cumulative = 0;
        let selectedVariant = test.defaultVariantId;

        for (const variant of test.variants) {
            cumulative += (variant.weight || 0);
            if (random < cumulative) {
                selectedVariant = variant.variantId;
                break;
            }
        }

        // 保存分配
        await userVariantRef.set({
            variant: selectedVariant,
            assignedAt: admin.firestore.FieldValue.serverTimestamp(),
            testId: testId,
        });

        return selectedVariant;
    } catch (error) {
        console.error(`Error getting/assigning variant for user ${userId}, test ${testId}:`, error);
        // 出錯時降級到默認
        const test = allNotificationTests.find(t => t.testId === testId);
        return test ? test.defaultVariantId : 'control';
    }
}

/**
 * 為用戶獲取完整的通知內容 (含自動 A/B 測試分配)
 * @param userId 用戶 ID
 * @param notificationType 通知類型 (e.g. 'match_success')
 * @param params 替換參數
 */
export async function getNotificationContentForUser(
    userId: string,
    notificationType: string,
    params: Record<string, string>
): Promise<{ title: string; body: string; variantId: string }> {
    const test = allNotificationTests.find(t => t.notificationType === notificationType);

    // 如果沒有配置 A/B 測試，返回默認
    if (!test) {
        console.warn(`No A/B test configured for notification type: ${notificationType}`);
        return { title: 'Notification', body: '', variantId: 'default' };
    }

    const variantId = await getUserVariant(userId, test.testId);
    const content = getNotificationCopy(test.testId, variantId, params);

    return {
        ...content,
        variantId
    };
}
