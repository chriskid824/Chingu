import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

if (admin.apps.length === 0) {
  admin.initializeApp();
}

/**
 * 透過 Callable Function 發送主題通知 (安全版本)
 *
 * 參數 (data):
 * - topic: 目標主題 (例如: loc_taipei, int_food)
 * - title: 通知標題
 * - body: 通知內容
 * - extraData: 額外資料 (可選)
 */
export const sendTopicNotification = functions.https.onCall(async (data, context) => {
  // 檢查用戶是否已登入
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'The function must be called while authenticated.'
    );
  }

  // 安全檢查：僅允許管理員發送廣播
  // 注意：這需要後端設置 Custom Claims (admin: true)
  // 或者在此處檢查特定的 UID / Email
  if (context.auth.token.admin !== true && context.auth.token.email !== 'admin@chingu.app') {
     throw new functions.https.HttpsError(
       'permission-denied',
       'Only admins can send topic notifications.'
     );
  }

  const { topic, title, body, extraData } = data;

  if (!topic || !title || !body) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'The function must be called with arguments "topic", "title", and "body".'
    );
  }

  try {
    const message: admin.messaging.Message = {
      topic: topic,
      notification: {
        title: title,
        body: body,
      },
      data: extraData || {},
      // Android 特定設定
      android: {
        notification: {
          channelId: 'chingu_rich_notifications',
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        },
      },
      // iOS 特定設定
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    const response = await admin.messaging().send(message);
    console.log(`Successfully sent message to topic ${topic}:`, response);
    return { success: true, messageId: response };
  } catch (error) {
    console.error('Error sending message:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Error sending notification',
      error
    );
  }
});
