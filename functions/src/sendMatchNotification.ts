import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { getNotificationCopy, matchSuccessTest } from "./notification_content";

// Ensure admin is initialized (prevent multiple initializations)
if (admin.apps.length === 0) {
  admin.initializeApp();
}

/**
 * Cloud Function to send notifications when a match occurs.
 *
 * Expected data:
 * - user1Id: string
 * - user2Id: string
 * - chatRoomId: string
 */
export const sendMatchNotification = functions.https.onCall(async (data, context) => {
    // Authentication check
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "Only authenticated users can trigger match notifications."
        );
    }

    const { user1Id, user2Id, chatRoomId } = data;

    if (!user1Id || !user2Id) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "user1Id and user2Id are required."
        );
    }

    try {
        // Fetch users to get names and FCM tokens
        const [user1Doc, user2Doc] = await Promise.all([
            admin.firestore().collection("users").doc(user1Id).get(),
            admin.firestore().collection("users").doc(user2Id).get()
        ]);

        if (!user1Doc.exists || !user2Doc.exists) {
             throw new functions.https.HttpsError(
                "not-found",
                "One or both users not found."
            );
        }

        const user1Data = user1Doc.data();
        const user2Data = user2Doc.data();

        const sendPromises: Promise<string>[] = [];

        // Send notification to User 1 (about User 2)
        if (user1Data?.fcmToken) {
            const variantId = getVariantId(user1Id);
            const copy = getNotificationCopy(matchSuccessTest.testId, variantId, {
                userName: user2Data?.name || "Someone",
            });

            const message = {
                token: user1Data.fcmToken,
                notification: {
                    title: copy.title,
                    body: copy.body,
                },
                data: {
                    type: "match_success",
                    chatRoomId: chatRoomId || "",
                    partnerId: user2Id,
                }
            };

            sendPromises.push(admin.messaging().send(message));
        }

        // Send notification to User 2 (about User 1)
        if (user2Data?.fcmToken) {
            const variantId = getVariantId(user2Id);
            const copy = getNotificationCopy(matchSuccessTest.testId, variantId, {
                userName: user1Data?.name || "Someone",
            });

            const message = {
                token: user2Data.fcmToken,
                notification: {
                    title: copy.title,
                    body: copy.body,
                },
                data: {
                    type: "match_success",
                    chatRoomId: chatRoomId || "",
                    partnerId: user1Id,
                }
            };

            sendPromises.push(admin.messaging().send(message));
        }

        if (sendPromises.length > 0) {
            await Promise.all(sendPromises);
        }

        return { success: true, sentCount: sendPromises.length };

    } catch (error) {
        console.error("Error sending match notifications:", error);
        // We don't throw error to client to avoid disrupting the match flow on client side if notification fails
        // But throwing internal error helps with debugging from client if they log it.
        // The client code will catch it.
        throw new functions.https.HttpsError("internal", "Failed to send match notifications.");
    }
});

/**
 * Deterministically select a variant based on user ID.
 */
function getVariantId(userId: string): string {
    const variants = matchSuccessTest.variants.map(v => v.variantId);

    // Simple string hash
    let hash = 0;
    for (let i = 0; i < userId.length; i++) {
        const char = userId.charCodeAt(i);
        hash = ((hash << 5) - hash) + char;
        hash = hash & hash; // Convert to 32bit integer
    }

    const index = Math.abs(hash) % variants.length;
    return variants[index];
}
