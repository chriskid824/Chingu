import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Interface for the request data
interface BroadcastRequest {
  title: string;
  body: string;
  type: 'global' | 'targeted';
  recipients?: string[]; // List of user IDs for targeted
  image?: string; // Optional image URL
  link?: string; // Optional deep link
  actionType?: string; // e.g., 'event', 'webview'
  actionData?: any; // Will be JSON encoded
}

export const sendBroadcast = functions.https.onCall(async (data: BroadcastRequest, context) => {
  // 1. Authentication check
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'The function must be called while authenticated.'
    );
  }

  const { title, body, type, recipients, image, link, actionType, actionData } = data;

  if (!title || !body || !type) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'The function must be called with title, body, and type.'
    );
  }

  const notificationPayload: admin.messaging.Notification = {
    title,
    body,
    ...(image && { imageUrl: image }),
  };

  const dataPayload: { [key: string]: string } = {
    click_action: 'FLUTTER_NOTIFICATION_CLICK',
    ...(link && { link }),
    ...(image && { image }),
    ...(actionType && { actionType }),
    ...(actionData && { actionData: JSON.stringify(actionData) }),
  };

  try {
    if (type === 'global') {
      // Send to 'all_users' topic
      const message: admin.messaging.Message = {
        notification: notificationPayload,
        data: dataPayload,
        topic: 'all_users',
      };

      const messageId = await admin.messaging().send(message);
      return { success: true, messageId, target: 'global' };

    } else if (type === 'targeted') {
      if (!recipients || recipients.length === 0) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Recipients list is required for targeted notifications.'
        );
      }

      const db = admin.firestore();
      const tokens: string[] = [];

      // Fetch tokens. Limit to 10 parallel requests to be safe, or just Promise.all if list is small.
      // Assuming manageable list size for "targeted".
      const userDocs = await Promise.all(
        recipients.map(uid => db.collection('users').doc(uid).get())
      );

      for (const doc of userDocs) {
        if (doc.exists) {
          const userData = doc.data();
          if (userData && userData.fcmToken) {
            tokens.push(userData.fcmToken);
          }
        }
      }

      if (tokens.length === 0) {
        return { success: false, message: 'No valid tokens found for recipients.' };
      }

      // Check if tokens list > 500 (Multicast limit is 500)
      const batches = [];
      while (tokens.length > 0) {
          batches.push(tokens.splice(0, 500));
      }

      let successCount = 0;
      let failureCount = 0;

      for (const batchTokens of batches) {
           const message: admin.messaging.MulticastMessage = {
            notification: notificationPayload,
            data: dataPayload,
            tokens: batchTokens,
          };

          const batchResponse = await admin.messaging().sendEachForMulticast(message);
          successCount += batchResponse.successCount;
          failureCount += batchResponse.failureCount;
      }

      return {
        success: true,
        successCount,
        failureCount,
        target: 'targeted'
      };

    } else {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Invalid notification type. Must be "global" or "targeted".'
      );
    }
  } catch (error) {
    console.error('Error sending broadcast:', error);
    throw new functions.https.HttpsError('internal', 'Error sending notification.', error);
  }
});
