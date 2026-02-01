import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { getNotificationCopy, matchSuccessTest } from './notification_content';

export const sendMatchNotification = functions.https.onCall(async (data, context) => {
    // 1. Authentication check
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be logged in.');
    }
    const senderId = context.auth.uid;
    const { otherUserId } = data;

    if (!otherUserId) {
         throw new functions.https.HttpsError('invalid-argument', 'otherUserId is required.');
    }

    // 2. Initialize Admin SDK if needed
    if (!admin.apps.length) {
        admin.initializeApp();
    }

    const db = admin.firestore();

    try {
        // 3. Fetch user documents
        const [senderDoc, otherDoc] = await Promise.all([
            db.collection('users').doc(senderId).get(),
            db.collection('users').doc(otherUserId).get()
        ]);

        if (!senderDoc.exists || !otherDoc.exists) {
            console.log(`User not found: Sender ${senderId} exists? ${senderDoc.exists}, Other ${otherUserId} exists? ${otherDoc.exists}`);
            return;
        }

        const senderData = senderDoc.data();
        const otherData = otherDoc.data();

        const senderName = senderData?.name || 'Someone';
        const otherName = otherData?.name || 'Someone';

        const promises = [];

        // 4. Send to Other User
        const otherToken = otherData?.fcmToken;
        if (otherToken) {
             const content = getNotificationCopy(
                 matchSuccessTest.testId,
                 'control',
                 { userName: senderName }
             );

             const message = {
                 token: otherToken,
                 notification: {
                     title: content.title,
                     body: content.body,
                 },
                 data: {
                     actionType: 'match_history',
                     userId: senderId,
                     click_action: 'FLUTTER_NOTIFICATION_CLICK'
                 },
                 android: {
                     notification: {
                         clickAction: 'FLUTTER_NOTIFICATION_CLICK'
                     }
                 },
                 apns: {
                     payload: {
                         aps: {
                             category: 'match_success'
                         }
                     }
                 }
             };
             promises.push(admin.messaging().send(message));
        }

        // 5. Send to Sender (Me)
        const senderToken = senderData?.fcmToken;
        if (senderToken) {
             const content = getNotificationCopy(
                 matchSuccessTest.testId,
                 'control',
                 { userName: otherName }
             );

             const message = {
                 token: senderToken,
                 notification: {
                     title: content.title,
                     body: content.body,
                 },
                 data: {
                     actionType: 'match_history',
                     userId: otherUserId,
                     click_action: 'FLUTTER_NOTIFICATION_CLICK'
                 },
                 android: {
                     notification: {
                         clickAction: 'FLUTTER_NOTIFICATION_CLICK'
                     }
                 },
                 apns: {
                     payload: {
                         aps: {
                             category: 'match_success'
                         }
                     }
                 }
             };
             promises.push(admin.messaging().send(message));
        }

        await Promise.all(promises);
        console.log(`Match notifications sent for ${senderId} and ${otherUserId}`);

    } catch (error) {
        console.error('Error sending match notification:', error);
        throw new functions.https.HttpsError('internal', 'Failed to send notification.');
    }
});
