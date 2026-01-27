import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { getNotificationCopy, matchSuccessTest } from "./notification_content";

// Ensure admin is initialized
if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Cloud Function to send notifications when a match occurs.
 * This function should be called by the client when a mutual like is detected.
 *
 * Data params:
 * - matchedUserId: string (The ID of the user who was just matched with)
 */
export const notifyMatch = functions.https.onCall(async (data, context) => {
    // 1. Authentication check
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "The function must be called while authenticated."
        );
    }

    const callerId = context.auth.uid;
    const { matchedUserId } = data;

    // 2. Validation
    if (!matchedUserId || typeof matchedUserId !== 'string') {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "The function must be called with one argument 'matchedUserId'."
        );
    }

    if (callerId === matchedUserId) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Cannot match with yourself."
        );
    }

    try {
        const db = admin.firestore();

        // 3. Fetch users in parallel
        const [callerDoc, matchedUserDoc] = await Promise.all([
            db.collection("users").doc(callerId).get(),
            db.collection("users").doc(matchedUserId).get(),
        ]);

        if (!callerDoc.exists || !matchedUserDoc.exists) {
            throw new functions.https.HttpsError("not-found", "User not found");
        }

        const callerData = callerDoc.data();
        const matchedUserData = matchedUserDoc.data();

        // 4. Fetch A/B test variants (optional, default to control if missing)
        // We look for the variant assignment in users/{userId}/ab_test_variants/{testId}
        const testId = matchSuccessTest.testId;

        const [callerVariantDoc, matchedUserVariantDoc] = await Promise.all([
            db.collection("users").doc(callerId).collection("ab_test_variants").doc(testId).get(),
            db.collection("users").doc(matchedUserId).collection("ab_test_variants").doc(testId).get(),
        ]);

        const callerVariant = callerVariantDoc.exists
            ? callerVariantDoc.data()?.variant
            : matchSuccessTest.defaultVariantId;

        const matchedUserVariant = matchedUserVariantDoc.exists
            ? matchedUserVariantDoc.data()?.variant
            : matchSuccessTest.defaultVariantId;

        // 5. Prepare notification messages
        const messages: admin.messaging.Message[] = [];

        // Message to Matched User (The one who was swiped on)
        if (matchedUserData?.fcmToken) {
            const { title, body } = getNotificationCopy(testId, matchedUserVariant, {
                userName: callerData?.name || 'Someone',
            });

            messages.push({
                token: matchedUserData.fcmToken,
                notification: { title, body },
                data: {
                    type: "match",
                    partnerId: callerId,
                    click_action: "FLUTTER_NOTIFICATION_CLICK",
                }
            });
        }

        // Message to Caller (The one who swiped)
        // We send this so they also get a push if they exit the app quickly
        if (callerData?.fcmToken) {
            const { title, body } = getNotificationCopy(testId, callerVariant, {
                userName: matchedUserData?.name || 'Someone',
            });

            messages.push({
                token: callerData.fcmToken,
                notification: { title, body },
                data: {
                    type: "match",
                    partnerId: matchedUserId,
                    click_action: "FLUTTER_NOTIFICATION_CLICK",
                }
            });
        }

        // 6. Send messages
        if (messages.length > 0) {
            const response = await admin.messaging().sendEach(messages);
            console.log(`Sent match notifications: ${response.successCount} success, ${response.failureCount} failure`);

            if (response.failureCount > 0) {
                response.responses.forEach((resp, idx) => {
                    if (!resp.success) {
                        console.error(`Error sending to token at index ${idx}:`, resp.error);
                    }
                });
            }
        }

        return { success: true };

    } catch (error) {
        console.error("Error sending match notification:", error);
        throw new functions.https.HttpsError("internal", "Unable to send notification");
    }
});
