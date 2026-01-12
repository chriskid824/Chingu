import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Initialize admin app if not already done
if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();

interface BroadcastData {
  title: string;
  body: string;
  imageUrl?: string;
  target: 'topic' | 'users' | 'all';
  targetValue?: string | string[]; // topic string or array of user IDs
  type?: string;
  actionType?: string;
  actionData?: string;
}

export const sendBroadcast = functions.https.onCall(async (data: BroadcastData, context) => {
  // 1. Authentication Check
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'The function must be called while authenticated.');
  }

  const uid = context.auth.uid;

  // 2. Admin Check
  try {
    const userDoc = await db.collection('users').doc(uid).get();
    const userData = userDoc.data();

    // Check isAdmin flag only (secure)
    const isAdmin = userData?.isAdmin === true;

    if (!isAdmin) {
      throw new functions.https.HttpsError('permission-denied', 'Only admins can send broadcasts.');
    }
  } catch (error) {
    console.error('Error fetching user for admin check:', error);
    throw new functions.https.HttpsError('internal', 'Failed to verify admin privileges.');
  }

  // 3. Input Validation
  const { title, body, imageUrl, target, targetValue, type, actionType, actionData } = data;

  if (!title || !body) {
    throw new functions.https.HttpsError('invalid-argument', 'Title and body are required.');
  }

  // Construct Notification Payload (FCM v1 API)
  const baseMessage: any = {
    notification: {
      title,
      body,
    },
    data: {
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
      type: type || 'system',
      actionType: actionType || '',
      actionData: actionData || '',
      timestamp: Date.now().toString(),
    },
    android: {
      priority: 'high',
      notification: {
         channelId: 'chingu_rich_notifications', // Match client channel
      }
    },
    apns: {
      payload: {
        aps: {
          'mutable-content': 1,
          contentAvailable: true,
        }
      }
    }
  };

  if (imageUrl) {
    baseMessage.notification.image = imageUrl;
    baseMessage.data.imageUrl = imageUrl;
    baseMessage.android.notification.imageUrl = imageUrl;
    baseMessage.apns.fcmOptions = {
      imageUrl: imageUrl
    };
  }

  try {
    let response;

    if (target === 'topic' && typeof targetValue === 'string') {
       // Send to topic using v1 API
       console.log(`Sending broadcast to topic: ${targetValue}`);
       const message = { ...baseMessage, topic: targetValue };
       response = await admin.messaging().send(message);

    } else if (target === 'users' && Array.isArray(targetValue)) {
       // Send to specific users
       console.log(`Sending broadcast to ${targetValue.length} users`);

       // Fetch FCM tokens for these users
       const tokens: string[] = [];
       // Helper to fetch in batches
       const fetchTokens = async (userIds: string[]) => {
         const refs = userIds.map(id => db.collection('users').doc(id));
         // Batch fetch
         const chunks = [];
         for (let i = 0; i < refs.length; i += 10) {
           chunks.push(refs.slice(i, i + 10));
         }

         for (const chunk of chunks) {
            const snaps = await db.getAll(...chunk);
            snaps.forEach(snap => {
               if (snap.exists) {
                 const d = snap.data();
                 if (d?.fcmToken) tokens.push(d.fcmToken);
                 if (Array.isArray(d?.fcmTokens)) {
                   d?.fcmTokens.forEach((t: any) => {
                     if (typeof t === 'string' && !tokens.includes(t)) tokens.push(t);
                   });
                 }
               }
            });
         }
       };

       await fetchTokens(targetValue);

       if (tokens.length > 0) {
         // sendEachForMulticast (v1 API equivalent for batch sending)
         // Note: tokens list size limit for multicast is 500 in v1 API usually?
         // Actually sendEachForMulticast splits automatically or we should check docs.
         // sendMulticast (legacy) handled 500. sendEachForMulticast takes array of messages or one message with tokens?
         // Wait, sendEachForMulticast takes MulticastMessage which has 'tokens' array.
         // It sends a separate message for each token but allows batching logic internally/convenience.
         // It returns BatchResponse.

         // Let's safe guard with 500 chunks just in case, though sendEachForMulticast might handle it.
         // Official docs say: "The tokens array can contain up to 500 tokens."

         const batchResponses = [];
         for (let i = 0; i < tokens.length; i += 500) {
            const batchTokens = tokens.slice(i, i + 500);
            const message = { ...baseMessage, tokens: batchTokens };
            batchResponses.push(await admin.messaging().sendEachForMulticast(message));
         }

         // Aggregate results
         const successCount = batchResponses.reduce((acc, r) => acc + r.successCount, 0);
         const failureCount = batchResponses.reduce((acc, r) => acc + r.failureCount, 0);
         response = { successCount, failureCount, batches: batchResponses.length };

       } else {
         console.warn('No tokens found for targeted users.');
         return { success: false, message: 'No valid tokens found for targeted users.' };
       }

    } else if (target === 'all') {
       // Global broadcast via topic
       console.log('Sending broadcast to all_users topic');
       const message = { ...baseMessage, topic: 'all_users' };
       response = await admin.messaging().send(message);

    } else {
        throw new functions.https.HttpsError('invalid-argument', 'Invalid target configuration.');
    }

    return { success: true, result: response };

  } catch (error) {
    console.error('Broadcast execution error:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send broadcast.', error);
  }
});
