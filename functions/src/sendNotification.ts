import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Ensure admin is initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

export const sendNotification = functions.https.onCall(async (data, context) => {
  // 1. Verify user identity
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'The function must be called while authenticated.'
    );
  }

  const { recipientId, title, body, type, data: extraData } = data;

  if (!recipientId || !title || !body) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'The function must be called with arguments "recipientId", "title", and "body".'
    );
  }

  try {
    // 2. Get target user FCM Tokens
    const userDoc = await admin.firestore().collection('users').doc(recipientId).get();

    if (!userDoc.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        'The recipient user does not exist.'
      );
    }

    const userData = userDoc.data();
    let fcmTokens: string[] = userData?.fcmTokens || [];

    // Fallback compatibility: check single fcmToken if list is empty
    if (fcmTokens.length === 0 && userData?.fcmToken) {
      fcmTokens = [userData.fcmToken];
    }

    if (!fcmTokens || fcmTokens.length === 0) {
      console.log(`No FCM tokens found for user ${recipientId}`);
      return { success: false, message: 'No FCM tokens found for user.' };
    }

    // 3. Send Notification using FCM Admin SDK
    const message: admin.messaging.MulticastMessage = {
      tokens: fcmTokens,
      notification: {
        title: title,
        body: body,
      },
      data: {
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
        type: type || 'system',
        ...extraData,
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'channel_messages',
        },
      },
      apns: {
        payload: {
          aps: {
            contentAvailable: true,
          },
        },
      },
    };

    const response = await admin.messaging().sendMulticast(message);

    // Clean up invalid tokens
    if (response.failureCount > 0) {
      const failedTokens: string[] = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          const error = resp.error;
          if (
            error?.code === 'messaging/invalid-registration-token' ||
            error?.code === 'messaging/registration-token-not-registered'
          ) {
            failedTokens.push(fcmTokens[idx]);
          }
        }
      });

      if (failedTokens.length > 0) {
        await admin.firestore().collection('users').doc(recipientId).update({
          fcmTokens: admin.firestore.FieldValue.arrayRemove(...failedTokens),
        });
        console.log(`Removed ${failedTokens.length} invalid tokens for user ${recipientId}`);
      }
    }

    return {
      success: true,
      failureCount: response.failureCount,
      successCount: response.successCount,
    };
  } catch (error) {
    console.error('Error sending notification:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Error sending notification.'
    );
  }
});
