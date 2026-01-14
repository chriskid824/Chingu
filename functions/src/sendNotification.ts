import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

/**
 * Sends a notification to a specific user using FCM.
 *
 * Expected data:
 * - targetUserId: string (The UID of the user to send the notification to)
 * - title: string (Notification title)
 * - body: string (Notification body)
 * - data: Record<string, string> (Optional data payload)
 */
export const sendNotification = functions.https.onCall(async (data, context) => {
    // 1. Verify user identity
    if (!context.auth) {
        throw new functions.https.HttpsError(
            'unauthenticated',
            'The function must be called while authenticated.'
        );
    }

    const { targetUserId, title, body, payload } = data;

    if (!targetUserId || !title || !body) {
        throw new functions.https.HttpsError(
            'invalid-argument',
            'The function must be called with arguments "targetUserId", "title", and "body".'
        );
    }

    // Validate payload values are strings if payload exists
    if (payload) {
        for (const [key, value] of Object.entries(payload)) {
            if (typeof value !== 'string') {
                throw new functions.https.HttpsError(
                    'invalid-argument',
                    `Payload value for key "${key}" must be a string.`
                );
            }
        }
    }

    try {
        // 2. Get target user FCM Tokens
        const userDoc = await admin.firestore().collection('users').doc(targetUserId).get();
        if (!userDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'Target user not found.');
        }

        const userData = userDoc.data();
        let tokens: string[] = [];

        if (userData && userData.fcmTokens && Array.isArray(userData.fcmTokens)) {
            tokens = userData.fcmTokens;
        } else {
             console.log(`No fcmTokens field found for user ${targetUserId}`);
        }

        if (tokens.length === 0) {
             return { success: false, message: 'User has no registered devices.' };
        }

        // 3. Send notification using FCM Admin SDK
        const message: admin.messaging.MulticastMessage = {
            tokens: tokens,
            notification: {
                title: title,
                body: body,
            },
            data: payload || {},
            android: {
                notification: {
                    sound: 'default',
                }
            },
            apns: {
                payload: {
                    aps: {
                        sound: 'default',
                    }
                }
            }
        };

        const batchResponse = await admin.messaging().sendEachForMulticast(message);

        // Cleanup invalid tokens
        if (batchResponse.failureCount > 0) {
            const failedTokens: string[] = [];
            batchResponse.responses.forEach((resp, idx) => {
                if (!resp.success && resp.error) {
                    const errorCode = resp.error.code;
                    if (errorCode === 'messaging/invalid-registration-token' ||
                        errorCode === 'messaging/registration-token-not-registered') {
                        failedTokens.push(tokens[idx]);
                    }
                }
            });

            // Remove failed tokens from Firestore
            if (failedTokens.length > 0) {
                await admin.firestore().collection('users').doc(targetUserId).update({
                    fcmTokens: admin.firestore.FieldValue.arrayRemove(...failedTokens)
                });
            }
        }

        return {
            success: true,
            successCount: batchResponse.successCount,
            failureCount: batchResponse.failureCount
        };

    } catch (error) {
        console.error('Error sending notification:', error);
        throw new functions.https.HttpsError('internal', 'Unable to send notification.');
    }
});
