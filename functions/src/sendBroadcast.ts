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

    // Check if user is in an 'admins' collection
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
    } = data;

    // Validate required fields
    if (!title || !body) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Title and body are required."
        );
    }

    // Validate targetCities limit
    if (targetCities && targetCities.length > 30) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Cannot target more than 30 cities at once."
        );
    }

    // Ensure customData values are strings
    const formattedData: { [key: string]: string } = {};
    if (customData) {
        for (const [key, value] of Object.entries(customData)) {
            formattedData[key] = String(value);
        }
    }

    try {
        let targetTokens: string[] = [];

        if (targetAll) {
            // Send to all users - use topic subscription
            const message: admin.messaging.Message = {
                notification: {
                    title: title,
                    body: body,
                    ...(imageUrl && { imageUrl }),
                },
                data: formattedData,
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
            // Send to specific users using getAll to avoid 'in' query limits
            const userRefs = targetUserIds.map((uid: string) =>
                admin.firestore().collection("users").doc(uid)
            );

            const userDocs = await admin.firestore().getAll(...userRefs);

            targetTokens = userDocs
                .map((doc) => doc.data()?.fcmToken)
                .filter((token) => token); // Remove null/undefined tokens
        } else if (targetCities && targetCities.length > 0) {
            // Send to users in specific cities
            const citiesLower = targetCities.map((city: string) => city.toLowerCase());
            const usersSnapshot = await admin.firestore()
                .collection("users")
                .where("city", "in", citiesLower)
                .get();

            targetTokens = usersSnapshot.docs
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
        // Note: tokens list can be up to 500. If more, we need to batch.
        // sendEachForMulticast handles batching internally if tokens > 500?
        // No, sendEachForMulticast sends to each token individually but in a batch request.
        // It accepts up to 500 tokens.
        // We should implement manual batching if we expect > 500 tokens.
        // For this task, I will add simple batching logic for robustness.

        const BATCH_SIZE = 500;
        let successCount = 0;
        let failureCount = 0;

        for (let i = 0; i < targetTokens.length; i += BATCH_SIZE) {
            const batchTokens = targetTokens.slice(i, i + BATCH_SIZE);

            const message: admin.messaging.MulticastMessage = {
                notification: {
                    title: title,
                    body: body,
                    ...(imageUrl && { imageUrl }),
                },
                data: formattedData,
                tokens: batchTokens,
            };

            const response = await admin.messaging().sendEachForMulticast(message);
            successCount += response.successCount;
            failureCount += response.failureCount;

            if (response.failureCount > 0) {
                console.log(`Batch ${i / BATCH_SIZE}: Failed to send ${response.failureCount} messages`);
                response.responses.forEach((resp, idx) => {
                    if (!resp.success) {
                        console.error(`Error sending to token ${batchTokens[idx]}:`, resp.error);
                    }
                });
            }
        }

        console.log(`Successfully sent ${successCount} messages, failed ${failureCount}`);

        // Log the broadcast
        await admin.firestore().collection("broadcast_logs").add({
            title,
            body,
            targetType: targetUserIds.length > 0 ? "users" : "cities",
            targetIds: targetUserIds.length > 0 ? targetUserIds : targetCities,
            sentBy: context.auth.uid,
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
            successCount,
            failureCount,
        });

        return {
            success: true,
            successCount,
            failureCount,
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
