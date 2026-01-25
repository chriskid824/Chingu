import * as admin from "firebase-admin";

// / 通知文案 A/B 測試配置
// / 用於測試不同通知文案對用戶參與度的影響
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
    },
    {
      variantId: "friendly",
      title: "找到新朋友啦!",
      body: "{userName} 也喜歡你！快去打個招呼吧",
      emoji: "💕",
    },
    {
      variantId: "urgent",
      title: "別錯過這個緣分!",
      body: "你與 {userName} 互相喜歡，現在就開始聊天吧",
      emoji: "✨",
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
    },
    {
      variantId: "casual",
      title: "{userName}",
      body: "「{messagePreview}」",
    },
    {
      variantId: "engaging",
      title: "{userName} 想和你聊聊",
      body: "{messagePreview}",
      emoji: "💬",
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
    },
    {
      variantId: "countdown",
      title: "倒數計時!",
      body: "{eventName} 還有 {timeLeft} 就要開始了",
      emoji: "⏰",
    },
    {
      variantId: "motivating",
      title: "準備好了嗎?",
      body: "{eventName} 即將開始，期待與你見面!",
      emoji: "🌟",
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
    },
    {
      variantId: "curious",
      title: "你錯過了什麼?",
      body: "上來看看有誰對你感興趣吧",
      emoji: "👀",
    },
    {
      variantId: "fomo",
      title: "有 {count} 個人喜歡了你!",
      body: "快來看看是誰吧",
      emoji: "💝",
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
 * @param {string} testId 測試 ID
 * @param {string} variantId 變體 ID
 * @param {Record<string, string>} params 文案替換參數
 * @return {object} 通知標題和內容
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
    title = title.replace(`{${key}}`, value);
    body = body.replace(`{${key}}`, value);
  }

  // 添加 emoji
  if (variant.emoji) {
    title = `${variant.emoji} ${title}`;
  }

  return {title, body};
}

/**
 * 獲取用戶的通知文案（自動處理 A/B 測試分配）
 * @param {admin.firestore.Firestore} db Firestore 實例
 * @param {string} userId 用戶 ID
 * @param {string} testId 測試 ID
 * @param {Record<string, string>} params 文案替換參數
 * @return {Promise<object>} 通知標題和內容
 */
export async function getUserNotificationCopy(
  db: admin.firestore.Firestore,
  userId: string,
  testId: string,
  params: Record<string, string>
): Promise<{ title: string; body: string }> {
  // Check existing assignment
  const variantRef = db.collection("users").doc(userId).collection("ab_test_variants").doc(testId);
  let variantId: string;

  const doc = await variantRef.get();
  if (doc.exists) {
    variantId = doc.data()?.variantId;
  } else {
    // Assign new
    const test = allNotificationTests.find((t) => t.testId === testId);
    if (!test) return {title: "", body: ""};

    // Random assignment
    const variants = test.variants;
    const selected = variants[Math.floor(Math.random() * variants.length)];
    variantId = selected.variantId;

    await variantRef.set({
      variantId,
      assignedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  return getNotificationCopy(testId, variantId, params);
}
