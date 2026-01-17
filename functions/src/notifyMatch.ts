import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { getNotificationCopy, matchSuccessTest } from "./notification_content";

if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Cloud Function to notify users when a match is successful.
 * Called by the client when a mutual like is detected.
 *
 * Arguments:
 * - matchedUserId: The ID of the user who was swiped/matched.
 */
export const notifyMatch = functions.https.onCall(async (data, context) => {
    // 1. Auth check
    if (!context.auth) {
        throw new functions.https.HttpsError(
            'unauthenticated',
            'The function must be called while authenticated.'
        );
    }

    const currentUserId = context.auth.uid;
    const { matchedUserId } = data;

    if (!matchedUserId || typeof matchedUserId !== 'string') {
        throw new functions.https.HttpsError(
            'invalid-argument',
            'The function must be called with one argument "matchedUserId" containing the user ID of the match.'
        );
    }

    try {
        const db = admin.firestore();
        const swipesRef = db.collection('swipes');

        // 2. Verify mutual match in Firestore
        // Check if current user liked matched user
        const currentUserSwipe = await swipesRef
            .where('userId', '==', currentUserId)
            .where('targetUserId', '==', matchedUserId)
            .where('isLike', '==', true)
            .limit(1)
            .get();

        // Check if matched user liked current user
        const matchedUserSwipe = await swipesRef
            .where('userId', '==', matchedUserId)
            .where('targetUserId', '==', currentUserId)
            .where('isLike', '==', true)
            .limit(1)
            .get();

        if (currentUserSwipe.empty || matchedUserSwipe.empty) {
            // Note: In a highly concurrent environment, there might be a slight delay in consistency,
            // but usually read-after-write from the same client is fine.
            // However, the matchedUserSwipe was written by another device earlier.
            throw new functions.https.HttpsError(
                'failed-precondition',
                'No mutual match found or verification failed.'
            );
        }

        // 3. Get user profiles for names and tokens
        const userRef = db.collection('users');
        const [currentUserDoc, matchedUserDoc] = await Promise.all([
            userRef.doc(currentUserId).get(),
            userRef.doc(matchedUserId).get()
        ]);

        if (!currentUserDoc.exists || !matchedUserDoc.exists) {
            throw new functions.https.HttpsError(
                'not-found',
                'One or both users not found.'
            );
        }

        const currentUserData = currentUserDoc.data();
        const matchedUserData = matchedUserDoc.data();

        // 4. Send notifications

        // Helper to send notification to a single user
        const sendNotificationToUser = async (
            targetId: string,
            partnerName: string,
            partnerId: string
        ) => {
            try {
                // Get target user doc again? We already have it but need to be sure about token and variant.
                // We have the doc snapshot, so we can use it.
                const targetDoc = targetId === currentUserId ? currentUserDoc : matchedUserDoc;
                const targetData = targetDoc.data();
                const targetToken = targetData?.fcmToken;

                if (!targetToken) {
                    console.log(`No FCM token for user ${targetId}`);
                    return;
                }

                // Get A/B test variant
                // Stored in subcollection: users/{userId}/ab_test_variants/{testId}
                let variantId = matchSuccessTest.defaultVariantId;
                try {
                    const variantDoc = await userRef
                        .doc(targetId)
                        .collection('ab_test_variants')
                        .doc(matchSuccessTest.testId)
                        .get();

                    if (variantDoc.exists) {
                        variantId = variantDoc.data()?.variant || variantId;
                    }
                } catch (e) {
                    console.error(`Error fetching variant for ${targetId}:`, e);
                }

                const content = getNotificationCopy(matchSuccessTest.testId, variantId, { userName: partnerName });

                const message = {
                    notification: {
                        title: content.title,
                        body: content.body,
                    },
                    data: {
                        type: 'match_success',
                        matchUserId: partnerId,
                        click_action: 'FLUTTER_NOTIFICATION_CLICK', // Standard for Flutter
                    },
                    token: targetToken,
                };

                await admin.messaging().send(message);
                console.log(`Notification sent to ${targetId} (variant: ${variantId})`);

            } catch (e) {
                console.error(`Error sending notification to ${targetId}:`, e);
                // Don't throw, so we continue to send to the other user if one fails
            }
        };

        // Send to both in parallel
        await Promise.all([
            sendNotificationToUser(currentUserId, matchedUserData?.name || 'Someone', matchedUserId),
            sendNotificationToUser(matchedUserId, currentUserData?.name || 'Someone', currentUserId),
        ]);

        return { success: true };

    } catch (error) {
        console.error('Error in notifyMatch:', error);
        if (error instanceof functions.https.HttpsError) {
            throw error;
        }
        throw new functions.https.HttpsError('internal', 'Internal error', error);
    }
});
