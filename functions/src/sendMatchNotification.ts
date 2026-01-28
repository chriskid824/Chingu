import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Cloud Function to send match notifications to both users.
 * Verifies that a mutual match exists before sending.
 *
 * Arguments:
 * - targetUserId: The UID of the matched user.
 */
export const sendMatchNotification = functions.https.onCall(async (data, context) => {
    // Verify that the request is made by an authenticated user
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "Only authenticated users can send notifications."
        );
    }

    const currentUserId = context.auth.uid;
    const { targetUserId } = data;

    if (!targetUserId) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "targetUserId is required."
        );
    }

    try {
        const firestore = admin.firestore();

        // 1. Verify Mutual Match
        const mySwipe = await firestore.collection("swipes")
            .where("userId", "==", currentUserId)
            .where("targetUserId", "==", targetUserId)
            .where("isLike", "==", true)
            .limit(1)
            .get();

        const theirSwipe = await firestore.collection("swipes")
            .where("userId", "==", targetUserId)
            .where("targetUserId", "==", currentUserId)
            .where("isLike", "==", true)
            .limit(1)
            .get();

        if (mySwipe.empty || theirSwipe.empty) {
            console.warn(`Attempt to send match notification without mutual match. User: ${currentUserId}, Target: ${targetUserId}`);
            throw new functions.https.HttpsError(
                "failed-precondition",
                "No mutual match found."
            );
        }

        // 2. Fetch User Profiles (for names and tokens)
        const [currentUserDoc, targetUserDoc] = await Promise.all([
            firestore.collection("users").doc(currentUserId).get(),
            firestore.collection("users").doc(targetUserId).get(),
        ]);

        const currentUserData = currentUserDoc.data();
        const targetUserData = targetUserDoc.data();

        if (!currentUserData || !targetUserData) {
            throw new functions.https.HttpsError("not-found", "User profile not found.");
        }

        const currentName = currentUserData.name || "Someone";
        const targetName = targetUserData.name || "Someone";

        const currentToken = currentUserData.fcmToken;
        const targetToken = targetUserData.fcmToken;

        const notifications = [];

        // Notify Current User
        if (currentToken) {
            notifications.push(admin.messaging().send({
                notification: {
                    title: "配對成功！",
                    body: `恭喜！你與 ${targetName} 配對成功`,
                },
                data: {
                    type: "match",
                    partnerId: targetUserId,
                },
                token: currentToken,
            }));
        }

        // Notify Target User
        if (targetToken) {
            notifications.push(admin.messaging().send({
                notification: {
                    title: "配對成功！",
                    body: `恭喜！你與 ${currentName} 配對成功`,
                },
                data: {
                    type: "match",
                    partnerId: currentUserId,
                },
                token: targetToken,
            }));
        }

        const results = await Promise.all(notifications);
        console.log(`Sent ${results.length} match notifications.`);

        return { success: true, count: results.length };

    } catch (error) {
        console.error("Error sending match notification:", error);
        if (error instanceof functions.https.HttpsError) {
            throw error;
        }
        throw new functions.https.HttpsError(
            "internal",
            "Failed to send match notification.",
            error
        );
    }
});
