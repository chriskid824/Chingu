import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { getNotificationCopy, matchSuccessTest } from "./notification_content";

// Ensure Firebase Admin is initialized
if (!admin.apps.length) {
    admin.initializeApp();
}

const db = admin.firestore();

/**
 * Cloud Function to send match notifications to two users.
 * Can be called from the client when a match is successfully created.
 *
 * Data:
 * - user1Id: string
 * - user2Id: string
 */
export const sendMatchNotification = functions.https.onCall(async (data, context) => {
    // Verify authentication
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "The function must be called while authenticated."
        );
    }

    const { user1Id, user2Id } = data;

    if (!user1Id || !user2Id) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Both user1Id and user2Id are required."
        );
    }

    try {
        // Fetch both users in parallel
        const [user1Doc, user2Doc] = await Promise.all([
            db.collection("users").doc(user1Id).get(),
            db.collection("users").doc(user2Id).get()
        ]);

        if (!user1Doc.exists || !user2Doc.exists) {
            throw new functions.https.HttpsError(
                "not-found",
                "One or both users not found."
            );
        }

        const user1Data = user1Doc.data();
        const user2Data = user2Doc.data();

        if (!user1Data || !user2Data) {
            throw new functions.https.HttpsError(
                "data-loss",
                "User data is missing."
            );
        }

        // Helper to send notification to one user about the other
        const notifyUser = async (recipientId: string, recipientData: any, otherUserData: any) => {
            if (!recipientData.fcmToken) {
                console.log(`No FCM token for user ${recipientId}`);
                return;
            }

            // Determine A/B test variant based on recipient ID hash
            // Simple hash: sum of char codes % number of variants
            const sum = recipientId.split("").reduce((acc, char) => acc + char.charCodeAt(0), 0);
            const variantIndex = sum % matchSuccessTest.variants.length;
            const variantId = matchSuccessTest.variants[variantIndex].variantId;

            // Get copy
            const copy = getNotificationCopy(
                matchSuccessTest.testId,
                variantId,
                { userName: otherUserData.name || "Someone" }
            );

            // Prepare notification payload
            const payload = {
                notification: {
                    title: copy.title,
                    body: copy.body,
                },
                data: {
                    type: "match",
                    matchId: recipientId < otherUserData.uid ? `${recipientId}_${otherUserData.uid}` : `${otherUserData.uid}_${recipientId}`, // chatRoomId convention?
                    partnerId: otherUserData.uid,
                    click_action: "FLUTTER_NOTIFICATION_CLICK",
                },
                token: recipientData.fcmToken,
            };

            // Send FCM
            try {
                await admin.messaging().send(payload);
                console.log(`Sent match notification to ${recipientId}`);
            } catch (error) {
                console.error(`Error sending FCM to ${recipientId}:`, error);
            }

            // Add to Firestore notifications collection
            try {
                await db.collection("notifications").add({
                    userId: recipientId,
                    type: "match",
                    title: copy.title,
                    message: copy.body,
                    data: payload.data,
                    isRead: false,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    relatedUserId: otherUserData.uid, // Useful for navigation
                });
            } catch (error) {
                console.error(`Error adding notification to Firestore for ${recipientId}:`, error);
            }
        };

        // Send to both users
        await Promise.all([
            notifyUser(user1Id, user1Data, { ...user2Data, uid: user2Id }),
            notifyUser(user2Id, user2Data, { ...user1Data, uid: user1Id })
        ]);

        return { success: true };

    } catch (error) {
        console.error("Error in sendMatchNotification:", error);
        throw new functions.https.HttpsError(
            "internal",
            "Failed to send match notifications.",
            error
        );
    }
});
