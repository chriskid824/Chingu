import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Defensive initialization
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
            const message: admin.messaging.Message = {
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
            // Firestore 'in' query limit is 30
            const chunkSize = 30;
            const chunks: string[][] = [];
            for (let i = 0; i < targetUserIds.length; i += chunkSize) {
                chunks.push(targetUserIds.slice(i, i + chunkSize));
            }

            const snapshots = await Promise.all(chunks.map((chunk) =>
                admin.firestore()
                    .collection("users")
                    .where(admin.firestore.FieldPath.documentId(), "in", chunk)
                    .get()
            ));

            targetTokens = snapshots.flatMap((snapshot) =>
                snapshot.docs.map((doc) => doc.data().fcmToken)
            ).filter((token) => token); // Remove null/undefined tokens

        } else if (targetCities && targetCities.length > 0) {
            if (targetCities.length > 30) {
                 throw new functions.https.HttpsError(
                    "invalid-argument",
                    "Cannot target more than 30 cities at once."
                );
            }

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

        // Batch tokens into groups of 500
        const batchSize = 500;
        const batches: string[][] = [];
        for (let i = 0; i < targetTokens.length; i += batchSize) {
            batches.push(targetTokens.slice(i, i + batchSize));
        }

        console.log(`Sending broadcast to ${targetTokens.length} devices in ${batches.length} batches.`);

        let totalSuccessCount = 0;
        let totalFailureCount = 0;
        const errors: any[] = [];

        for (const batchTokens of batches) {
             const message: admin.messaging.MulticastMessage = {
                notification: {
                    title: title,
                    body: body,
                    ...(imageUrl && { imageUrl }),
                },
                data: customData || {},
                tokens: batchTokens,
            };

            const response = await admin.messaging().sendEachForMulticast(message);

            totalSuccessCount += response.successCount;
            totalFailureCount += response.failureCount;

            if (response.failureCount > 0) {
                response.responses.forEach((resp, idx) => {
                    if (!resp.success) {
                        errors.push({
                            token: batchTokens[idx],
                            error: resp.error
                        });
                        console.error(`Error sending to token ${batchTokens[idx]}:`, resp.error);
                    }
                });
            }
        }

        console.log(`Successfully sent ${totalSuccessCount} messages. Failed: ${totalFailureCount}`);

        // Log the broadcast
        await admin.firestore().collection("broadcast_logs").add({
            title,
            body,
            targetType: targetUserIds.length > 0 ? "users" : "cities",
            targetIds: targetUserIds.length > 0 ? targetUserIds : targetCities,
            sentBy: context.auth.uid,
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
            successCount: totalSuccessCount,
            failureCount: totalFailureCount,
        });

        return {
            success: true,
            successCount: totalSuccessCount,
            failureCount: totalFailureCount,
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
