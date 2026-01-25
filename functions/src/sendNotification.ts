import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

/**
 * 發送單一通知的 Cloud Function
 *
 * 用途:
 * - 允許已驗證的用戶向特定用戶發送 FCM 通知
 *
 * 參數:
 * - targetUserId: 目標用戶 ID (必填)
 * - title: 通知標題 (必填)
 * - body: 通知內容 (必填)
 * - data: 自定義數據 (選填)
 * - imageUrl: 圖片連結 (選填)
 */
export const sendNotification = functions.https.onCall(async (data, context) => {
  // 1. 驗證用戶身份
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "只有已驗證的用戶可以發送通知。"
    );
  }

  const {
    targetUserId,
    title,
    body,
    data: customData,
    imageUrl,
  } = data;

  // 2. 驗證必要參數
  if (!targetUserId || !title || !body) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "必須提供 targetUserId, title 和 body。"
    );
  }

  try {
    // 3. 獲取目標用戶的 FCM Token
    const userDoc = await admin.firestore()
      .collection("users")
      .doc(targetUserId)
      .get();

    if (!userDoc.exists) {
      throw new functions.https.HttpsError(
        "not-found",
        "找不到目標用戶。"
      );
    }

    const fcmToken = userDoc.data()?.fcmToken;

    if (!fcmToken) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "目標用戶沒有有效的 FCM Token。"
      );
    }

    // 4. 發送 FCM 通知
    const message = {
      notification: {
        title: title,
        body: body,
        ...(imageUrl && {imageUrl}),
      },
      data: customData || {},
      token: fcmToken,
    };

    const response = await admin.messaging().send(message);
    console.log(`成功發送通知給 ${targetUserId}:`, response);

    return {
      success: true,
      messageId: response,
      targetUserId: targetUserId,
    };
  } catch (error) {
    console.error("發送通知時發生錯誤:", error);

    // 如果錯誤已經是 HttpsError，直接拋出
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    throw new functions.https.HttpsError(
      "internal",
      "發送通知失敗。",
      error
    );
  }
});
