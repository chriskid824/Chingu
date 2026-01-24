import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Ensure admin is initialized
if (!admin.apps.length) {
    admin.initializeApp();
}

/**
 * Triggered when a new notification is created in a user's notification subcollection.
 * Sends a push notification to the user's device using FCM.
 */
export const onNotificationCreated = functions.firestore
    .document("users/{userId}/notifications/{notificationId}")
    .onCreate(async (snapshot, context) => {
        const notification = snapshot.data();
        const userId = context.params.userId;

        if (!notification) {
            console.log("No notification data found");
            return;
        }

        try {
            // Get user's FCM token
            const userDoc = await admin.firestore().collection("users").doc(userId).get();
            const userData = userDoc.data();

            if (!userData || !userData.fcmToken) {
                console.log(`No FCM token found for user ${userId}`);
                return;
            }

            const fcmToken = userData.fcmToken;

            // Check if push notifications are enabled for this user
            if (userData.pushNotificationsEnabled === false) {
                 console.log(`Push notifications disabled for user ${userId}`);
                 return;
            }

            // Construct payload
            const payload: admin.messaging.Message = {
                token: fcmToken,
                notification: {
                    title: notification.title || "New Notification",
                    body: notification.message || "You have a new message",
                },
                data: {
                    type: notification.type || "system",
                    actionType: notification.actionType || "",
                    actionData: notification.actionData || "",
                    notificationId: snapshot.id,
                },
            };

             if (notification.imageUrl) {
                 // Android
                 (payload as any).android = {
                     notification: {
                         imageUrl: notification.imageUrl
                     }
                 };
                 // iOS
                 (payload as any).apns = {
                     payload: {
                         aps: {
                             "mutable-content": 1
                         }
                     },
                     fcm_options: {
                         image: notification.imageUrl
                     }
                 };
             }

            // Send message
            await admin.messaging().send(payload);
            console.log(`Push notification sent to user ${userId}`);

        } catch (error) {
            console.error(`Error sending push notification to user ${userId}:`, error);
        }
    });
