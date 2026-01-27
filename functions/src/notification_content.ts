import {Firestore} from "firebase-admin/firestore";

// / 通知文案 A/B 測試配置
// / 用於測試不同通知文案對用戶參與度的影響
export interface NotificationCopyVariant {
    variantId: string;
    title: string;
    body: string;
    emoji?: string;
    weight?: number; // 權重 (0-100), 默認為均分
}

export interface NotificationCopyTest {
    testId: string;
    notificationType: string;
    variants: NotificationCopyVariant[];
    defaultVariantId: string;
}

// A/B 測試: 配對成功通知
export const matchSuccessTest: NotificationCopyTest = {
  testId: "match_success_copy_v1",
  notificationType: "match_success",
  defaultVariantId: "control",
  variants: [
    {
      variantId: "control",
      title: "配對成功!",
      body: "你與 {userName} 配對成功了",
      emoji: "🎉",
      weight: 34,
    },
    {
      variantId: "friendly",
      title: "找到新朋友啦!",
      body: "{userName} 也喜歡你！快去打個招呼吧",
      emoji: "💕",
      weight: 33,
    },
    {
      variantId: "urgent",
      title: "別錯過這個緣分!",
      body: "你與 {userName} 互相喜歡，現在就開始聊天吧",
      emoji: "✨",
      weight: 33,
    },
  ],
};

// A/B 測試: 新訊息通知
export const newMessageTest: NotificationCopyTest = {
  testId: "new_message_copy_v1",
  notificationType: "new_message",
  defaultVariantId: "control",
  variants: [
    {
      variantId: "control",
      title: "{userName} 傳來訊息",
      body: "{messagePreview}",
      weight: 34,
    },
    {
      variantId: "casual",
      title: "{userName}",
      body: "「{messagePreview}」",
      weight: 33,
    },
    {
      variantId: "engaging",
      title: "{userName} 想和你聊聊",
      body: "{messagePreview}",
      emoji: "💬",
      weight: 33,
    },
  ],
};

// A/B 測試: 活動提醒通知
export const eventReminderTest: NotificationCopyTest = {
  testId: "event_reminder_copy_v1",
  notificationType: "event_reminder",
  defaultVariantId: "control",
  variants: [
    {
      variantId: "control",
      title: "活動提醒",
      body: "{eventName} 將於 {time} 開始",
      emoji: "📅",
      weight: 34,
    },
    {
      variantId: "countdown",
      title: "倒數計時!",
      body: "{eventName} 還有 {timeLeft} 就要開始了",
      emoji: "⏰",
      weight: 33,
    },
    {
      variantId: "motivating",
      title: "準備好了嗎?",
      body: "{eventName} 即將開始，期待與你見面!",
      emoji: "🌟",
      weight: 33,
    },
  ],
};

// A/B 測試: 無活動提示
export const inactivityTest: NotificationCopyTest = {
  testId: "inactivity_copy_v1",
  notificationType: "inactivity_reminder",
  defaultVariantId: "control",
  variants: [
    {
      variantId: "control",
      title: "好久不見",
      body: "有新的朋友在等著認識你",
      weight: 34,
    },
    {
      variantId: "curious",
      title: "你錯過了什麼?",
      body: "上來看看有誰對你感興趣吧",
      emoji: "👀",
      weight: 33,
    },
    {
      variantId: "fomo",
      title: "有 {count} 個人喜歡了你!",
      body: "快來看看是誰吧",
      emoji: "💝",
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
 * 根據權重隨機分配變體
 * @param {NotificationCopyTest} test - 測試配置
 * @return {string} 分配的變體 ID
 */
export function assignVariant(test: NotificationCopyTest): string {
  const random = Math.random() * 100;
  let cumulative = 0;

  for (const variant of test.variants) {
    // 如果沒有設置權重，則假設均分 (這是一個簡化的處理，實際上最好都有權重)
    const weight = variant.weight ?? (100 / test.variants.length);
    cumulative += weight;
    if (random < cumulative) {
      return variant.variantId;
    }
  }

  return test.defaultVariantId;
}

/**
 * 根據用戶分配的變體獲取通知文案
 * @param {string} testId - 測試 ID
 * @param {string} variantId - 變體 ID
 * @param {Record<string, string>} params - 文案替換參數
 * @return {{title: string, body: string}} 通知標題和內容
 */
export function getNotificationCopy(
  testId: string,
  variantId: string,
  params: Record<string, string>
): { title: string; body: string } {
  const test = allNotificationTests.find((t) => t.testId === testId);
  if (!test) {
    return {title: "Notification", body: ""};
  }

  const variant = test.variants.find((v) => v.variantId === variantId) ||
        test.variants.find((v) => v.variantId === test.defaultVariantId);

  if (!variant) {
    return {title: "Notification", body: ""};
  }

  let title = variant.title;
  let body = variant.body;

  // 替換參數
  for (const [key, value] of Object.entries(params)) {
    // 使用 global replace 以防同一個參數出現多次
    title = title.replace(new RegExp(`{${key}}`, "g"), value);
    body = body.replace(new RegExp(`{${key}}`, "g"), value);
  }

  // 添加 emoji
  if (variant.emoji) {
    title = `${variant.emoji} ${title}`;
  }

  return {title, body};
}

/**
 * 獲取用戶的通知文案 (包含自動分配變體邏輯)
 * @param {Firestore} firestore - Firestore 實例
 * @param {string} userId - 用戶 ID
 * @param {string} notificationType - 通知類型
 * @param {Record<string, string>} params - 文案替換參數
 * @return {Promise<{title: string, body: string}>} 通知標題和內容
 */
export async function getUserNotificationContent(
  firestore: Firestore,
  userId: string,
  notificationType: string,
  params: Record<string, string>
): Promise<{ title: string; body: string }> {
  const test = allNotificationTests.find((t) => t.notificationType === notificationType);

  // 如果找不到對應的測試，返回空或默認
  if (!test) {
    console.warn(`No A/B test found for notification type: ${notificationType}`);
    return {title: "Notification", body: ""};
  }

  const testId = test.testId;
  let variantId = test.defaultVariantId;

  try {
    // 1. 嘗試從 Firestore 獲取用戶已分配的變體
    const variantDocRef = firestore
      .collection("users")
      .doc(userId)
      .collection("ab_test_variants")
      .doc(testId);

    const docSnapshot = await variantDocRef.get();

    if (docSnapshot.exists) {
      variantId = docSnapshot.data()?.variant as string || test.defaultVariantId;
    } else {
      // 2. 如果未分配，則進行分配並保存
      variantId = assignVariant(test);

      // 異步保存，不阻塞返回 (或者應該 await 以確保一致性? 這裡選擇 await)
      await variantDocRef.set({
        variant: variantId,
        assignedAt: new Date(), // 使用 serverTimestamp 更好，但需要引入 FieldValue
        testId: testId,
      });
    }
  } catch (error) {
    console.error(`Error fetching/assigning AB test variant for user ${userId}:`, error);
    // 出錯時降級使用默認變體
    variantId = test.defaultVariantId;
  }

  return getNotificationCopy(testId, variantId, params);
}
