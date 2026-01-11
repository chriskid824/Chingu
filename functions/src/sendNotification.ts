import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

interface SendNotificationData {
  userId: string;
  title: string;
  body: string;
  data?: { [key: string]: string };
}

/**
 * 發送 FCM 通知
 *
 * 該函數是一個 Callable Function，供客戶端調用。
 * 它會驗證調用者的身份，獲取目標用戶的 FCM Tokens，並發送通知。
 */
export const sendNotification = functions.https.onCall(async (data: SendNotificationData, context) => {
  // 1. 驗證用戶身份
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      '使用者必須登入才能發送通知 (User must be logged in to send notifications).'
    );
  }

  const { userId, title, body, data: notificationData } = data;

  // 驗證輸入參數
  if (!userId || !title || !body) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      '必須提供目標 userId, title 和 body (Target userId, title, and body are required).'
    );
  }

  try {
    // 2. 獲取目標用戶 FCM Tokens
    // 假設 tokens 存儲在 users/{userId} 文檔中的 fcmTokens 字段 (Array) 或 fcmToken (String)
    const userDoc = await admin.firestore().collection('users').doc(userId).get();

    if (!userDoc.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        '找不到目標用戶 (Target user not found).'
      );
    }

    const userData = userDoc.data();
    let tokens: string[] = [];

    if (userData?.fcmTokens && Array.isArray(userData.fcmTokens)) {
      tokens = userData.fcmTokens;
    } else if (userData?.fcmToken && typeof userData.fcmToken === 'string') {
      tokens = [userData.fcmToken];
    }

    if (tokens.length === 0) {
      console.log(`User ${userId} has no FCM tokens.`);
      return { success: false, message: 'User has no FCM tokens registered.' };
    }

    // 3. 使用 FCM Admin SDK 發送通知
    const message: admin.messaging.MulticastMessage = {
      tokens: tokens,
      notification: {
        title: title,
        body: body,
      },
      data: notificationData || {},
      android: {
        notification: {
          sound: 'default',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    const response = await admin.messaging().sendMulticast(message);

    // 清理無效 tokens (Optional but recommended)
    if (response.failureCount > 0) {
      const failedTokens: string[] = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          failedTokens.push(tokens[idx]);
        }
      });
      // 這裡可以選擇從 Firestore 移除無效 tokens，暫時只做 log
      console.log('List of tokens that caused failures: ' + failedTokens);
    }

    console.log(`Successfully sent message: ${response.successCount} messages sent.`);

    return {
      success: true,
      sentCount: response.successCount,
      failureCount: response.failureCount
    };

  } catch (error) {
    console.error('Error sending notification:', error);
    throw new functions.https.HttpsError(
      'internal',
      '發送通知時發生錯誤 (Error sending notification).',
      error
    );
  }
});
