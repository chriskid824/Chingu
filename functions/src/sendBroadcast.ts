import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

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
        requiredSetting, // e.g., 'marketing_promo', 'event_reminder'
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

        // Helper to check settings
        const shouldSendToUser = (userData: any): boolean => {
            const settings = userData.notificationSettings || {};

            // Check global push setting (default to true if missing)
            if (settings.push_enabled === false) return false;

            // Check specific setting if required
            if (requiredSetting && settings[requiredSetting] === false) return false;

            return true;
        };

        if (targetAll) {
            // Send to all users - use topic subscription
            // Note: Topic messaging does not respect individual Firestore settings!
            // Client side should manage topic subscription based on settings.
            const message = {
                notification: {
                    title: title,
                    body: body,
                    ...(imageUrl && { imageUrl }),
                },
                data: customData || {},
                topic: "all_users",
            };

            const response = await admin.messaging().send(message);
            console.log("Successfully sent broadcast to all users:", response);

            // Log the broadcast
            await admin.firestore().collection("broadcast_logs").add({
                title,
                body,
                targetType: "all",
                sentBy: context.auth.uid,
                sentAt: admin.firestore.FieldValue.serverTimestamp(),
                messageId: response,
            });

            return { success: true, messageId: response, recipients: "all" };
        } else if (targetUserIds && targetUserIds.length > 0) {
            // Send to specific users
            const usersSnapshot = await admin.firestore()
                .collection("users")
                .where(admin.firestore.FieldPath.documentId(), "in", targetUserIds)
                .get();

            targetTokens = usersSnapshot.docs
                .filter(doc => shouldSendToUser(doc.data()))
                .map((doc) => doc.data().fcmToken)
                .filter((token) => token); // Remove null/undefined tokens
        } else if (targetCities && targetCities.length > 0) {
            // Send to users in specific cities
            const citiesLower = targetCities.map((city: string) => city.toLowerCase());
            const usersSnapshot = await admin.firestore()
                .collection("users")
                .where("city", "in", citiesLower)
                .get();

            targetTokens = usersSnapshot.docs
                .filter(doc => shouldSendToUser(doc.data()))
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
