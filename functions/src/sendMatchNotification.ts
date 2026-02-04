import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { getNotificationCopy, matchSuccessTest } from "./notification_content";

/**
 * Sends push notifications to both users when a match occurs.
 *
 * @param partnerId The ID of the matched user.
 * @param chatRoomId The ID of the created chat room (optional, for navigation).
 */
export const sendMatchNotification = functions.https.onCall(async (data, context) => {
    // 1. Authentication check
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "The function must be called while authenticated."
        );
    }

    const currentUserId = context.auth.uid;
    const { partnerId, chatRoomId } = data;

    if (!partnerId) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "The function must be called with a partnerId."
        );
    }

    try {
        const db = admin.firestore();

        // 2. Fetch user profiles
        const [currentUserDoc, partnerUserDoc] = await Promise.all([
            db.collection("users").doc(currentUserId).get(),
            db.collection("users").doc(partnerId).get(),
        ]);

        if (!currentUserDoc.exists || !partnerUserDoc.exists) {
            throw new functions.https.HttpsError(
                "not-found",
                "One or both users not found."
            );
        }

        const currentUser = currentUserDoc.data();
        const partnerUser = partnerUserDoc.data();

        if (!currentUser || !partnerUser) {
            throw new functions.https.HttpsError("not-found", "User data is empty.");
        }

        // 3. Send notifications to both users
        const notifications = [];

        // Notification to Current User (User A)
        if (currentUser.fcmToken) {
            notifications.push(
                sendNotificationToUser(
                    db,
                    currentUserId,
                    currentUser.fcmToken,
                    partnerUser.name || "Someone",
                    partnerUser.avatarUrl,
                    chatRoomId,
                    partnerId // The 'other' user from A's perspective is B
                )
            );
        }

        // Notification to Partner User (User B)
        if (partnerUser.fcmToken) {
            notifications.push(
                sendNotificationToUser(
                    db,
                    partnerId,
                    partnerUser.fcmToken,
                    currentUser.name || "Someone",
                    currentUser.avatarUrl,
                    chatRoomId,
                    currentUserId // The 'other' user from B's perspective is A
                )
            );
        }

        await Promise.all(notifications);

        return { success: true };

    } catch (error) {
        console.error("Error sending match notifications:", error);
        throw new functions.https.HttpsError(
            "internal",
            "Failed to send match notifications.",
            error
        );
    }
});

async function sendNotificationToUser(
    db: admin.firestore.Firestore,
    userId: string,
    token: string,
    otherUserName: string,
    otherUserAvatar: string | undefined,
    chatRoomId: string | undefined,
    otherUserId: string
) {
    // 1. Get A/B Test Variant
    let variantId = matchSuccessTest.defaultVariantId;
    try {
        const variantDoc = await db.doc(`users/${userId}/ab_test_variants/${matchSuccessTest.testId}`).get();
        if (variantDoc.exists) {
            variantId = variantDoc.data()?.variantId || variantId;
        }
    } catch (e) {
        console.warn(`Failed to fetch AB test variant for user ${userId}`, e);
    }

    // 2. Generate Copy
    const { title, body } = getNotificationCopy(matchSuccessTest.testId, variantId, {
        userName: otherUserName,
    });

    // 3. Send Message
    const message = {
        notification: {
            title,
            body,
        },
        data: {
            type: "match_success",
            chatRoomId: chatRoomId || "",
            partnerId: otherUserId,
            url: "/chat_detail", // Deep link support if needed
            click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        token: token,
    };

    try {
        await admin.messaging().send(message);
        console.log(`Match notification sent to ${userId}`);
    } catch (error) {
        console.error(`Failed to send FCM to ${userId}:`, error);
        // Don't throw, just log. We want to try sending to the other user even if one fails.
    }
}
