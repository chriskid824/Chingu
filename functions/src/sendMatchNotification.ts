import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { getNotificationCopy, getVariantForUser, matchSuccessTest } from "./notification_content";

if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Cloud Function to send match notifications to both users
 * Triggered when a match is confirmed
 */
export const sendMatchNotification = functions.https.onCall(async (data, context) => {
    // Verify authentication
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "Only authenticated users can send match notifications."
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
        // Fetch users concurrently
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

        if (!user1Data || !user2Data) {
             throw new functions.https.HttpsError(
                "data-loss",
                "User data is missing."
            );
        }

        const results = await Promise.all([
            _sendToUser(user1Id, user1Data, user2Id, user2Data), // Notify user 1 about user 2
            _sendToUser(user2Id, user2Data, user1Id, user1Data)  // Notify user 2 about user 1
        ]);

        return {
            success: true,
            results: results
        };

    } catch (error) {
        console.error("Error sending match notification:", error);
        throw new functions.https.HttpsError(
            "internal",
            "Failed to send match notifications.",
            error
        );
    }
});

async function _sendToUser(
    recipientId: string,
    recipientData: any,
    partnerId: string,
    partnerData: any
) {
    const fcmToken = recipientData.fcmToken;
    if (!fcmToken) {
        console.log(`No FCM token for user ${recipientId}`);
        return { userId: recipientId, success: false, reason: "no_token" };
    }

    // A/B Testing Logic
    const variantId = getVariantForUser(matchSuccessTest.testId, recipientId);
    const copy = getNotificationCopy(matchSuccessTest.testId, variantId, {
        userName: partnerData.name || "Someone"
    });

    const message = {
        notification: {
            title: copy.title,
            body: copy.body,
        },
        data: {
            type: "match",
            partnerId: partnerId,
            partnerName: partnerData.name || "",
            partnerAvatarUrl: partnerData.avatarUrl || "",
            click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        token: fcmToken
    };

    // Add image to notification if available (depends on platform support)
    // iOS supports attachments via mutable content, Android supports image
    if (partnerData.avatarUrl) {
         (message.notification as any).imageUrl = partnerData.avatarUrl;
    }

    try {
        await admin.messaging().send(message);
        return { userId: recipientId, success: true };
    } catch (error) {
        console.error(`Failed to send to user ${recipientId}:`, error);
        return { userId: recipientId, success: false, error: error };
    }
}
