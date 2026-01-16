import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as crypto from "crypto";
import { matchSuccessTest, getNotificationCopy, NotificationCopyTest } from "./notification_content";

/**
 * Deterministically selects a variant for a user based on their ID.
 * Uses SHA-256 hash of the user ID to ensure consistent assignment.
 */
function getVariantId(userId: string, test: NotificationCopyTest): string {
    const hash = crypto.createHash("sha256").update(userId).digest("hex");
    // Use first 8 chars of hash to get a number
    const hashNum = parseInt(hash.substring(0, 8), 16);
    const index = hashNum % test.variants.length;
    return test.variants[index].variantId;
}

/**
 * Sends push notifications to both users when a match occurs.
 * This should be called by the client after a successful swipe.
 */
export const sendMatchNotification = functions.https.onCall(async (data, context) => {
    // 1. Verify Authentication
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "The function must be called while authenticated."
        );
    }

    const { user1Id, user2Id, chatRoomId } = data;

    if (!user1Id || !user2Id || !chatRoomId) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Missing required parameters: user1Id, user2Id, chatRoomId"
        );
    }

    // Verify Authorization: The caller must be one of the users involved in the match
    if (context.auth.uid !== user1Id && context.auth.uid !== user2Id) {
        throw new functions.https.HttpsError(
            "permission-denied",
            "You are not authorized to send this notification."
        );
    }

    try {
        const db = admin.firestore();

        // 2. Fetch User Data (Parallel)
        const [user1Doc, user2Doc] = await Promise.all([
            db.collection("users").doc(user1Id).get(),
            db.collection("users").doc(user2Id).get()
        ]);

        if (!user1Doc.exists || !user2Doc.exists) {
            throw new functions.https.HttpsError("not-found", "One or both users not found.");
        }

        const user1Data = user1Doc.data();
        const user2Data = user2Doc.data();

        if (!user1Data || !user2Data) {
            throw new functions.https.HttpsError("internal", "User data is empty.");
        }

        const user1Token = user1Data.fcmToken;
        const user2Token = user2Data.fcmToken;
        const user1Name = user1Data.name || "Someone";
        const user2Name = user2Data.name || "Someone";

        // 3. Prepare Notifications
        const sendToUser1 = async () => {
            if (!user1Token) return null;

            const variantId = getVariantId(user1Id, matchSuccessTest);
            const content = getNotificationCopy(matchSuccessTest.testId, variantId, {
                userName: user2Name
            });

            const message = {
                notification: {
                    title: content.title,
                    body: content.body,
                },
                data: {
                    type: "match_success",
                    chatRoomId: chatRoomId,
                    partnerId: user2Id,
                    click_action: "FLUTTER_NOTIFICATION_CLICK",
                },
                token: user1Token,
            };

            try {
                await admin.messaging().send(message);
                // Log stat
                await db.collection("notification_stats").add({
                    userId: user1Id,
                    type: "match_success",
                    variantId: variantId,
                    testId: matchSuccessTest.testId,
                    action: "sent",
                    timestamp: admin.firestore.FieldValue.serverTimestamp(),
                });
                return true;
            } catch (error) {
                console.error(`Error sending to user 1 (${user1Id}):`, error);
                return false;
            }
        };

        const sendToUser2 = async () => {
            if (!user2Token) return null;

            const variantId = getVariantId(user2Id, matchSuccessTest);
            const content = getNotificationCopy(matchSuccessTest.testId, variantId, {
                userName: user1Name
            });

            const message = {
                notification: {
                    title: content.title,
                    body: content.body,
                },
                data: {
                    type: "match_success",
                    chatRoomId: chatRoomId,
                    partnerId: user1Id,
                    click_action: "FLUTTER_NOTIFICATION_CLICK",
                },
                token: user2Token,
            };

            try {
                await admin.messaging().send(message);
                // Log stat
                await db.collection("notification_stats").add({
                    userId: user2Id,
                    type: "match_success",
                    variantId: variantId,
                    testId: matchSuccessTest.testId,
                    action: "sent",
                    timestamp: admin.firestore.FieldValue.serverTimestamp(),
                });
                return true;
            } catch (error) {
                console.error(`Error sending to user 2 (${user2Id}):`, error);
                return false;
            }
        };

        // 4. Send in Parallel
        const results = await Promise.all([sendToUser1(), sendToUser2()]);

        return {
            success: true,
            results: {
                user1: results[0],
                user2: results[1]
            }
        };

    } catch (error) {
        console.error("Error in sendMatchNotification:", error);
        throw new functions.https.HttpsError(
            "internal",
            "Failed to send match notifications.",
            error
        );
    }
});
