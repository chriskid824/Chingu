import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Callable function to create a match notification for another user.
 * This is called by User A when they match with User B.
 * It creates a notification document in User B's collection, which triggers onNotificationCreate.
 *
 * Arguments: { matchedUserId: string }
 */
export const notifyMatch = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "The function must be called while authenticated."
        );
    }

    const currentUserId = context.auth.uid;
    const { matchedUserId } = data;

    if (!matchedUserId) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "The function must be called with one argument 'matchedUserId'."
        );
    }

    try {
        // 1. Get current user data (to use name/photo in notification)
        const currentUserDoc = await admin.firestore().collection("users").doc(currentUserId).get();
        if (!currentUserDoc.exists) {
             throw new functions.https.HttpsError("not-found", "Current user not found");
        }
        const currentUser = currentUserDoc.data();
        const currentUserName = currentUser?.name || "Someone";
        // Assuming photoUrls is an array of strings
        const currentUserPhoto = (currentUser?.photoUrls && currentUser.photoUrls.length > 0)
            ? currentUser.photoUrls[0]
            : null;

        // 2. Create notification for the MATCHED user (User B)
        // User B matched with User A (Current User)
        const notificationForMatchedUser = {
            userId: matchedUserId,
            type: "match",
            title: "New Match! 🎉",
            message: `You matched with ${currentUserName}! Say hello now.`,
            imageUrl: currentUserPhoto,
            actionType: "open_chat",
            actionData: currentUserId, // Clicking opens chat with User A
            isRead: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        };

        await admin.firestore()
            .collection("users")
            .doc(matchedUserId)
            .collection("notifications")
            .add(notificationForMatchedUser);

        return { success: true };

    } catch (error) {
        console.error("Error in notifyMatch:", error);
        throw new functions.https.HttpsError("internal", "Failed to notify match");
    }
});
