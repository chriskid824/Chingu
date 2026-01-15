import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Initialize app if not already initialized
if (admin.apps.length === 0) {
  admin.initializeApp();
}

interface SendNotificationData {
  targetUserId: string;
  title: string;
  body: string;
  data?: { [key: string]: string };
}

export const sendNotification = functions.https.onCall(async (data: SendNotificationData, context) => {
  // 1. Verify User Identity
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'The function must be called while authenticated.'
    );
  }

  const { targetUserId, title, body, data: payloadData } = data;

  // Validate input
  if (!targetUserId || !title || !body) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'The function must be called with targetUserId, title, and body.'
    );
  }

  try {
    // 2. Get Target User FCM Token
    const userDoc = await admin.firestore().collection('users').doc(targetUserId).get();

    if (!userDoc.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        'Target user not found.'
      );
    }

    const userData = userDoc.data();
    const fcmToken = userData?.fcmToken;

    if (!fcmToken) {
        console.warn(`User ${targetUserId} does not have an FCM token.`);
        return { success: false, error: 'User has no FCM token' };
    }

    // 3. Send Notification using FCM Admin SDK
    // Check if fcmToken is a string or array, though we expect string based on field name
    if (typeof fcmToken !== 'string') {
        console.warn(`User ${targetUserId} has invalid FCM token format.`);
        return { success: false, error: 'Invalid FCM token format' };
    }

    const message: admin.messaging.Message = {
      token: fcmToken,
      notification: {
        title: title,
        body: body,
      },
      data: payloadData || {},
    };

    await admin.messaging().send(message);

    return { success: true };

  } catch (error) {
    console.error('Error sending notification:', error);
    // Re-throw HttpsError
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    // Generic error
    throw new functions.https.HttpsError(
      'internal',
      'An internal error occurred while sending the notification.'
    );
  }
});
