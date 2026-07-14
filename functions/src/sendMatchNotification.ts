import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { getNotificationContentForUser, matchSuccessTest } from "./notification_content";

// Ensure app is initialized
if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Sends a match notification to a user.
 * Intended to be called when a match occurs.
 *
 * Logic:
 * 1. Checks authentication.
 * 2. Fetches current user's details (name).
 * 3. Fetches target user's details (FCM token).
 * 4. Generates notification content using A/B testing logic based on target user's ID.
 * 5. Sends the notification via FCM.
 */
export const sendMatchNotification = functions.https.onCall(async (data, context) => {
    // 1. Authentication check
    if (!context.auth) {
        throw new functions.https.HttpsError(
            'unauthenticated',
            'The function must be called while authenticated.'
        );
    }

    const { otherUserId } = data;
    if (!otherUserId) {
        throw new functions.https.HttpsError(
            'invalid-argument',
            'The function must be called with an "otherUserId" argument.'
        );
    }

    try {
        // 2. Fetch Current User Profile (to get name)
        const currentUserDoc = await admin.firestore().collection('users').doc(context.auth.uid).get();
        const currentUserData = currentUserDoc.data();
        if (!currentUserData) {
            throw new functions.https.HttpsError('not-found', 'Current user not found');
        }
        const currentUserName = currentUserData.name || 'Someone';

        // 3. Fetch Target User Profile (for FCM token)
        const targetUserDoc = await admin.firestore().collection('users').doc(otherUserId).get();
        const targetUserData = targetUserDoc.data();
        if (!targetUserData) {
            throw new functions.https.HttpsError('not-found', 'Target user not found');
        }

        const fcmToken = targetUserData.fcmToken;
        if (!fcmToken) {
            console.log(`No FCM token for user ${otherUserId}. Notification skipped.`);
            return { success: false, reason: 'no-token' };
        }

        // 4. Get A/B Tested Content
        // We assign the variant based on the target user (otherUserId) because we want to measure their response.
        const content = getNotificationContentForUser(otherUserId, matchSuccessTest.testId, {
            userName: currentUserName
        });

        // 5. Send Notification
        const message = {
            notification: {
                title: content.title,
                body: content.body,
            },
            data: {
                type: 'match_success',
                matchUserId: context.auth.uid,
                click_action: 'FLUTTER_NOTIFICATION_CLICK'
            },
            token: fcmToken
        };

        await admin.messaging().send(message);
        console.log(`Match notification sent to ${otherUserId} using A/B test content.`);

        return { success: true };
    } catch (error) {
        console.error('Error sending match notification:', error);
        if (error instanceof functions.https.HttpsError) {
            throw error;
        }
        throw new functions.https.HttpsError('internal', 'Error sending notification', error);
    }
});
