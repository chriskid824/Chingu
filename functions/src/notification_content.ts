
// notification_content.ts

export interface NotificationContent {
  title: string;
  body: string;
}

export type ExperimentGroup = 'A' | 'B'; // A: Control, B: Variant

interface NotificationTemplate {
  title: string;
  body: string;
}

// 文案庫
const COPY_LIBRARY: Record<string, Record<ExperimentGroup, NotificationTemplate>> = {
  // 新配對通知
  match_new: {
    A: {
      title: '你有一位新配對！',
      body: '快來看看是誰對你有興趣。',
    },
    B: {
      title: '哇！有人對你有好感 😍',
      body: '緣分來了！點擊查看你的新配對。',
    },
  },
  // 新訊息通知
  message_new: {
    A: {
      title: '你收到一則新訊息',
      body: '查看 {name} 傳送的內容。',
    },
    B: {
      title: '{name} 刚刚傳送了一則訊息給你...',
      body: '不想知道 {name} 說了什麼嗎？👀',
    },
  },
  // 活動提醒 (1天前)
  event_reminder_1d: {
    A: {
      title: '活動提醒',
      body: '你的晚餐聚會將在明天舉行，別忘了參加！',
    },
    B: {
      title: '準備好享用美食了嗎？🍽️',
      body: '明天就是期待已久的晚餐聚會！記得準時出席喔。',
    },
  },
  // 活動邀請
  event_invite: {
    A: {
      title: '活動邀請',
      body: '有人邀請你參加一個晚餐活動。',
    },
    B: {
      title: '嘿！這裡有個晚餐很適合你 🥂',
      body: '發現一個你可能感興趣的聚會，快來看看吧！',
    },
  },
  // 系統通知 (預設不分組，或作為 fallback)
  system: {
    A: {
      title: '系統通知',
      body: '{message}',
    },
    B: {
      title: '來自 Chingu 的訊息',
      body: '{message}',
    },
  },
};

/**
 * 替換文案中的參數
 * @param text 原始文字
 * @param params 參數物件
 */
function formatText(text: string, params: Record<string, string> = {}): string {
  let result = text;
  for (const key in params) {
    result = result.replace(new RegExp(`{${key}}`, 'g'), params[key]);
  }
  return result;
}

/**
 * 根據類型和分組獲取通知文案
 * @param type 通知類型 (e.g., 'match_new', 'message_new')
 * @param group 用戶分組 ('A' or 'B')
 * @param params 動態參數 (e.g., { name: 'Alice' })
 */
export function getNotificationContent(
  type: string,
  group: ExperimentGroup = 'A', // 預設為 A 組 (對照組)
  params: Record<string, string> = {}
): NotificationContent {
  const templates = COPY_LIBRARY[type];

  if (!templates) {
    // 如果找不到類型，返回通用 fallback
    return {
      title: '新通知',
      body: '你有一則新通知',
    };
  }

  // 獲取對應分組的模板，如果 B 組沒有定義則 fallback 到 A 組
  const template = templates[group] || templates['A'];

  return {
    title: formatText(template.title, params),
    body: formatText(template.body, params),
  };
}

/**
 * 簡單的隨機分組函數 (用於測試或無用戶 ID 時)
 */
export function getRandomGroup(): ExperimentGroup {
  return Math.random() < 0.5 ? 'A' : 'B';
}
