import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Initialize Firebase Admin SDK if not already initialized
if (admin.apps.length === 0) {
  admin.initializeApp();
}

interface SendNotificationData {
  targetUserId: string;
  title: string;
  body: string;
  data?: Record<string, string>;
  image?: string;
}

/**
 * Cloud Function to send FCM notifications to a specific user.
 *
 * Verifies the caller is authenticated, fetches the target user's FCM tokens
 * from Firestore, and sends the notification using FCM Admin SDK.
 */
export const sendNotification = functions.https.onCall(async (data: SendNotificationData, context) => {
  // 1. Authenticate User
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'The function must be called while authenticated.'
    );
  }

  const { targetUserId, title, body, image } = data;
  const payloadData = data.data || {};

  // 2. Validate Input
  if (!targetUserId || !title || !body) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'The function must be called with targetUserId, title, and body.'
    );
  }

  try {
    // 3. Fetch Target User's FCM Tokens
    const userRef = admin.firestore().collection('users').doc(targetUserId);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      console.warn(`Target user ${targetUserId} not found.`);
      return { success: false, message: 'Target user not found.' };
    }

    const userData = userDoc.data();
    if (!userData) {
      return { success: false, message: 'User data is empty.' };
    }

    // Collect tokens from both 'fcmTokens' (array) and 'fcmToken' (string legacy)
    const tokens = new Set<string>();

    if (userData.fcmTokens && Array.isArray(userData.fcmTokens)) {
      userData.fcmTokens.forEach((t: any) => {
        if (typeof t === 'string' && t.trim().length > 0) tokens.add(t);
      });
    }

    if (userData.fcmToken && typeof userData.fcmToken === 'string' && userData.fcmToken.trim().length > 0) {
      tokens.add(userData.fcmToken);
    }

    if (tokens.size === 0) {
      console.log(`No valid FCM tokens found for user ${targetUserId}`);
      return { success: false, message: 'No tokens found for user.' };
    }

    const tokenList = Array.from(tokens);

    // 4. Construct the Multicast Message
    const message: admin.messaging.MulticastMessage = {
      tokens: tokenList,
      notification: {
        title: title,
        body: body,
      },
      data: payloadData,
      android: {
        notification: {
          sound: 'default',
          priority: 'high',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            contentAvailable: true,
          },
        },
      },
    };

    if (image) {
        if (!message.notification) message.notification = {};
        message.notification.imageUrl = image;
    }

    // 5. Send Notification
    const batchResponse = await admin.messaging().sendEachForMulticast(message);

    // 6. Cleanup Invalid Tokens
    if (batchResponse.failureCount > 0) {
      const invalidTokens: string[] = [];
      batchResponse.responses.forEach((resp, idx) => {
        if (!resp.success) {
          const errCode = resp.error?.code;
          if (
            errCode === 'messaging/invalid-registration-token' ||
            errCode === 'messaging/registration-token-not-registered'
          ) {
            invalidTokens.push(tokenList[idx]);
          }
        }
      });

      if (invalidTokens.length > 0) {
        console.log(`Removing ${invalidTokens.length} invalid tokens for user ${targetUserId}`);
        await userRef.update({
          fcmTokens: admin.firestore.FieldValue.arrayRemove(...invalidTokens),
        });
      }
    }

    return {
      success: true,
      successCount: batchResponse.successCount,
      failureCount: batchResponse.failureCount,
    };

  } catch (error) {
    console.error('Error in sendNotification:', error);
    throw new functions.https.HttpsError(
      'internal',
      'An internal error occurred while sending the notification.',
      error
    );
  }
});
