import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
    admin.initializeApp();
}

export const sendMatchNotification = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "Only authenticated users can trigger match notifications."
        );
    }

    const { matchedUserId1, matchedUserId2, chatRoomId } = data;

    // Security check: Ensure caller is one of the matched users
    if (context.auth.uid !== matchedUserId1 && context.auth.uid !== matchedUserId2) {
        throw new functions.https.HttpsError(
            "permission-denied",
            "User must be part of the match to trigger notification."
        );
    }

    if (!matchedUserId1 || !matchedUserId2) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "matchedUserId1 and matchedUserId2 are required."
        );
    }

    try {
        const db = admin.firestore();
        const [user1Doc, user2Doc] = await Promise.all([
            db.collection("users").doc(matchedUserId1).get(),
            db.collection("users").doc(matchedUserId2).get(),
        ]);

        if (!user1Doc.exists || !user2Doc.exists) {
            console.error(`One or both users not found: ${matchedUserId1}, ${matchedUserId2}`);
            return { success: false, error: "Users not found" };
        }

        const user1Data = user1Doc.data();
        const user2Data = user2Doc.data();

        const token1 = user1Data?.fcmToken;
        const token2 = user2Data?.fcmToken;

        const notifications: Promise<string>[] = [];

        // Notify User 1
        if (token1) {
            notifications.push(
                admin.messaging().send({
                    token: token1,
                    notification: {
                        title: "It's a Match!",
                        body: `You and ${user2Data?.name || "someone"} liked each other!`,
                    },
                    data: {
                        actionType: "open_chat",
                        actionData: chatRoomId || "",
                        click_action: "FLUTTER_NOTIFICATION_CLICK",
                    },
                })
            );
        }

        // Notify User 2
        if (token2) {
            notifications.push(
                admin.messaging().send({
                    token: token2,
                    notification: {
                        title: "It's a Match!",
                        body: `You and ${user1Data?.name || "someone"} liked each other!`,
                    },
                    data: {
                        actionType: "open_chat",
                        actionData: chatRoomId || "",
                        click_action: "FLUTTER_NOTIFICATION_CLICK",
                    },
                })
            );
        }

        await Promise.all(notifications);

        return { success: true };
    } catch (error) {
        console.error("Error sending match notification:", error);
        throw new functions.https.HttpsError("internal", "Failed to send notification");
    }
});
