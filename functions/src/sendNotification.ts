import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { getNotificationContent, NotificationType } from './notification_content';

// Initialize admin app if not already initialized
if (admin.apps.length === 0) {
  admin.initializeApp();
}

export const sendNotification = functions.https.onCall(async (data, context) => {
  // 1. Check authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'The function must be called while authenticated.'
    );
  }

  const { targetUserId, type, params } = data;

  if (!targetUserId || !type) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'The function must be called with "targetUserId" and "type".'
    );
  }

  try {
    // 2. Get user's FCM token
    const userDoc = await admin.firestore().collection('users').doc(targetUserId).get();
    if (!userDoc.exists) {
        console.log(`User ${targetUserId} not found.`);
        return { success: false, error: 'User not found' };
    }

    const userData = userDoc.data();
    const fcmToken = userData?.fcmToken;

    if (!fcmToken) {
        console.log(`User ${targetUserId} has no FCM token.`);
        return { success: false, error: 'No FCM token' };
    }

    // 3. Get notification content based on A/B test group
    const content = getNotificationContent(targetUserId, type as NotificationType, params || {});

    // 4. Send notification
    const message: admin.messaging.Message = {
      token: fcmToken,
      notification: {
        title: content.title,
        body: content.body,
      },
      data: {
        type: type,
        // Convert params values to string if necessary, as data payload supports strings only
        ...Object.keys(params || {}).reduce((acc, key) => {
            acc[key] = String(params[key]);
            return acc;
        }, {} as Record<string, string>),
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
    };

    const response = await admin.messaging().send(message);
    console.log('Successfully sent message:', response);

    return { success: true, messageId: response };
  } catch (error) {
    console.error('Error sending notification:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Unable to send notification',
      error
    );
  }
});
