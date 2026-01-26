import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Triggered when a new notification is created in a user's notification collection.
 * Sends a push notification to the user's device.
 */
export const onNotificationCreated = functions.firestore
    .document("users/{userId}/notifications/{notificationId}")
    .onCreate(async (snapshot, context) => {
        const userId = context.params.userId;
        const notificationData = snapshot.data();

        if (!notificationData) {
            console.log("No data in notification document");
            return;
        }

        try {
            // Get the user's FCM token
            const userDoc = await admin.firestore().collection("users").doc(userId).get();
            const userData = userDoc.data();

            if (!userData || !userData.fcmToken) {
                console.log(`No FCM token found for user ${userId}`);
                return;
            }

            const fcmToken = userData.fcmToken;

            // Check if notifications are enabled for this user
            // Defaults to true if not set
            const isMatch = notificationData.type === 'match';
            const isMessage = notificationData.type === 'message';

            if (isMatch && userData.notificationMatchEnabled === false) {
                 console.log(`Match notifications disabled for user ${userId}`);
                 return;
            }
            if (isMessage && userData.notificationMessageEnabled === false) {
                 console.log(`Message notifications disabled for user ${userId}`);
                 return;
            }

            // Construct the FCM message
            const message: admin.messaging.Message = {
                token: fcmToken,
                notification: {
                    title: notificationData.title,
                    body: notificationData.message,
                },
                data: {
                    click_action: "FLUTTER_NOTIFICATION_CLICK",
                    actionType: notificationData.actionType || "",
                    actionData: notificationData.actionData || "",
                    notificationId: context.params.notificationId,
                    type: notificationData.type || "system",
                },
                android: {
                    priority: "high",
                    notification: {
                        channelId: "chingu_rich_notifications",
                        clickAction: "FLUTTER_NOTIFICATION_CLICK",
                    }
                },
                apns: {
                    payload: {
                        aps: {
                            sound: "default",
                            badge: 1,
                        },
                    },
                },
            };

            // Add image if available
            if (notificationData.imageUrl) {
                // For Android
                if (message.android && message.android.notification) {
                     message.android.notification.imageUrl = notificationData.imageUrl;
                }
                // For iOS (mutable content)
                if (message.apns && message.apns.payload && message.apns.payload.aps) {
                    message.apns.payload.aps["mutable-content"] = 1;
                    // Usually handled by service extension with data payload, but some support existing url
                }
            }

            // Send the message
            await admin.messaging().send(message);
            console.log(`Successfully sent notification to user ${userId}`);

        } catch (error) {
            console.error(`Error sending notification to user ${userId}:`, error);
        }
    });
