import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Triggered when a new notification document is created in users/{userId}/notifications
 * Sends a push notification (FCM) to the user.
 */
export const onNotificationCreate = functions.firestore
    .document("users/{userId}/notifications/{notificationId}")
    .onCreate(async (snapshot, context) => {
        const userId = context.params.userId;
        const notificationData = snapshot.data();

        if (!notificationData) {
            console.log("No data in notification");
            return;
        }

        try {
            // Get user's FCM token
            const userDoc = await admin.firestore().collection("users").doc(userId).get();
            if (!userDoc.exists) {
                console.log(`User ${userId} does not exist`);
                return;
            }

            const userData = userDoc.data();
            if (!userData || !userData.fcmToken) {
                console.log(`No FCM token for user ${userId}`);
                return;
            }

            const token = userData.fcmToken;

            // Construct payload
            // Map 'message' field from Firestore to 'body' for FCM
            const payload: admin.messaging.Message = {
                notification: {
                    title: notificationData.title || "New Notification",
                    body: notificationData.message || "",
                },
                data: {
                    type: notificationData.type || "default",
                    actionType: notificationData.actionType || "",
                    actionData: notificationData.actionData || "",
                    click_action: "FLUTTER_NOTIFICATION_CLICK",
                },
                token: token,
            };

            if (notificationData.imageUrl) {
                payload.notification!.imageUrl = notificationData.imageUrl;
            }

            // Send message
            await admin.messaging().send(payload);
            console.log(`Notification sent to user ${userId}`);

        } catch (error) {
            console.error(`Error sending notification to ${userId}:`, error);
        }
    });
