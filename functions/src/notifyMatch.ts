import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { getNotificationCopy } from "./notification_content";

// Ensure firebase-admin is initialized
if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Cloud Function to notify users when a match is successful
 * This function is called by the client (MatchingService)
 */
export const notifyMatch = functions.https.onCall(async (data, context) => {
    // 1. Verify authentication
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "User must be logged in to trigger match notification."
        );
    }

    const { user1Id, user2Id, chatRoomId } = data;

    // 2. Validate parameters
    if (!user1Id || !user2Id || !chatRoomId) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Missing required parameters: user1Id, user2Id, or chatRoomId."
        );
    }

    // Security Check: Caller must be one of the participants
    if (context.auth.uid !== user1Id && context.auth.uid !== user2Id) {
        throw new functions.https.HttpsError(
            "permission-denied",
            "You can only trigger notifications for your own matches."
        );
    }

    try {
        // 3. Fetch both users' data to get FCM tokens and names
        const [user1Doc, user2Doc] = await Promise.all([
            admin.firestore().collection("users").doc(user1Id).get(),
            admin.firestore().collection("users").doc(user2Id).get()
        ]);

        if (!user1Doc.exists || !user2Doc.exists) {
            console.error(`One or both users not found: ${user1Id}, ${user2Id}`);
            // We don't throw error to client to avoid disrupting the match flow, just log it.
            // Or maybe we should return success: false?
            // Client ignores errors anyway.
            return { success: false, reason: "Users not found" };
        }

        const user1Data = user1Doc.data();
        const user2Data = user2Doc.data();

        if (!user1Data || !user2Data) {
            return { success: false, reason: "User data empty" };
        }

        // 4. Helper function to send notification
        const sendNotification = async (
            recipientId: string,
            recipientData: admin.firestore.DocumentData,
            partnerData: admin.firestore.DocumentData
        ) => {
            const fcmToken = recipientData.fcmToken;
            if (!fcmToken) {
                console.log(`User ${recipientId} has no FCM token.`);
                return;
            }

            // Determine variant (simple hashing for deterministic A/B testing)
            // Or use a stored preference if available.
            // Here we use user ID char code sum mod 3 for variant selection.
            const variants = ['control', 'friendly', 'urgent'];
            const variantId = variants[recipientId.charCodeAt(0) % variants.length];

            const { title, body } = getNotificationCopy('match_success_copy_v1', variantId, {
                userName: partnerData.name || 'Someone',
            });

            const message: admin.messaging.Message = {
                notification: {
                    title,
                    body,
                },
                data: {
                    actionType: 'open_chat',
                    actionData: chatRoomId, // Navigate to this chat room
                    type: 'match',
                    click_action: 'FLUTTER_NOTIFICATION_CLICK',
                },
                token: fcmToken,
            };

            try {
                await admin.messaging().send(message);
                console.log(`Match notification sent to ${recipientId} (Variant: ${variantId})`);
            } catch (error) {
                console.error(`Failed to send FCM to ${recipientId}:`, error);
                // Continue execution
            }
        };

        // 5. Send notifications to both users in parallel
        await Promise.all([
            sendNotification(user1Id, user1Data, user2Data),
            sendNotification(user2Id, user2Data, user1Data)
        ]);

        return { success: true };

    } catch (error) {
        console.error("Error in notifyMatch:", error);
        throw new functions.https.HttpsError(
            "internal",
            "Internal error while sending match notifications."
        );
    }
});
