import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

/**
 * Cloud Function for sending broadcast notifications
 * Can be called by admin to send global or targeted notifications
 * 
 * Usage:
 * - Global broadcast: targetAll = true
 * - City-specific: targetCities = ["taipei", "taichung"]
 * - User-specific: targetUserIds = ["uid1", "uid2"]
 */
export const sendBroadcast = functions.https.onCall(async (data, context) => {
    // Verify that the request is made by an authenticated user
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "Only authenticated users can send broadcasts."
        );
    }

    // TODO: Add admin role verification
    // For now, we'll check if user is in an 'admins' collection
    const adminDoc = await admin.firestore()
        .collection("admins")
        .doc(context.auth.uid)
        .get();

    if (!adminDoc.exists) {
        throw new functions.https.HttpsError(
            "permission-denied",
            "Only admins can send broadcast notifications."
        );
    }

    const {
        title,
        body,
        data: customData,
        targetAll = false,
        targetCities = [],
        targetUserIds = [],
        imageUrl,
        notificationType = 'system', // 'marketing', 'newsletter', 'appUpdates', 'system'
    } = data;

    // Validate required fields
    if (!title || !body) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Title and body are required."
        );
    }

    try {
        let targetTokens: string[] = [];

        if (targetAll) {
            // Send to all users - use topic subscription
            // If notificationType is specific (e.g. marketing), send to that topic instead of all_users
            let topic = "all_users";
            // Check if it's one of the topic-based categories
            if (['marketing', 'newsletter', 'appUpdates', 'app_updates'].includes(notificationType)) {
                 // Map camelCase to snake_case for topics
                 if (notificationType === 'appUpdates' || notificationType === 'app_updates') {
                     topic = 'app_updates';
                 } else {
                     topic = notificationType;
                 }
            }

            const message = {
                notification: {
                    title: title,
                    body: body,
                    ...(imageUrl && { imageUrl }),
                },
                data: customData || {},
                topic: topic,
            };

            const response = await admin.messaging().send(message);
            console.log(`Successfully sent broadcast to topic ${topic}:`, response);

            // Log the broadcast
            await admin.firestore().collection("broadcast_logs").add({
                title,
                body,
                targetType: "all",
                targetTopic: topic,
                sentBy: context.auth.uid,
                sentAt: admin.firestore.FieldValue.serverTimestamp(),
                messageId: response,
            });

            return { success: true, messageId: response, recipients: "topic:" + topic };
        } else if (targetUserIds && targetUserIds.length > 0) {
            // Send to specific users
            const usersSnapshot = await admin.firestore()
                .collection("users")
                .where(admin.firestore.FieldPath.documentId(), "in", targetUserIds)
                .get();

            // Filter users based on preferences
            targetTokens = usersSnapshot.docs
                .filter(doc => {
                    const userData = doc.data();
                    // If preference exists and is false, exclude. Default true.
                    if (userData.notificationPreferences &&
                        userData.notificationPreferences[notificationType] === false) {
                        return false;
                    }
                    return true;
                })
                .map((doc) => doc.data().fcmToken)
                .filter((token) => token); // Remove null/undefined tokens

        } else if (targetCities && targetCities.length > 0) {
            // Send to users in specific cities
            const citiesLower = targetCities.map((city: string) => city.toLowerCase());
            const usersSnapshot = await admin.firestore()
                .collection("users")
                .where("city", "in", citiesLower)
                .get();

            // Filter users based on preferences
            targetTokens = usersSnapshot.docs
                .filter(doc => {
                    const userData = doc.data();
                    if (userData.notificationPreferences &&
                        userData.notificationPreferences[notificationType] === false) {
                        return false;
                    }
                    return true;
                })
                .map((doc) => doc.data().fcmToken)
                .filter((token) => token);
        } else {
            throw new functions.https.HttpsError(
                "invalid-argument",
                "Must specify targetAll, targetUserIds, or targetCities."
            );
        }

        if (targetTokens.length === 0) {
            throw new functions.https.HttpsError(
                "not-found",
                "No users found with FCM tokens for the specified criteria."
            );
        }

        // Send multicast message
        const message = {
            notification: {
                title: title,
                body: body,
                ...(imageUrl && { imageUrl }),
            },
            data: customData || {},
            tokens: targetTokens,
        };

        const response = await admin.messaging().sendEachForMulticast(message);

        console.log(`Successfully sent ${response.successCount} messages`);
        if (response.failureCount > 0) {
            console.log(`Failed to send ${response.failureCount} messages`);
            response.responses.forEach((resp, idx) => {
                if (!resp.success) {
                    console.error(`Error sending to token ${targetTokens[idx]}:`, resp.error);
                }
            });
        }

        // Log the broadcast
        await admin.firestore().collection("broadcast_logs").add({
            title,
            body,
            targetType: targetUserIds.length > 0 ? "users" : "cities",
            targetIds: targetUserIds.length > 0 ? targetUserIds : targetCities,
            sentBy: context.auth.uid,
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
            successCount: response.successCount,
            failureCount: response.failureCount,
        });

        return {
            success: true,
            successCount: response.successCount,
            failureCount: response.failureCount,
            totalTargets: targetTokens.length,
        };
    } catch (error) {
        console.error("Error sending broadcast:", error);
        throw new functions.https.HttpsError(
            "internal",
            "Failed to send broadcast notification.",
            error
        );
    }
});
