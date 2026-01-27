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
            // Firestore 'in' query supports up to 30 items. We batch queries to handle more.
            const chunks = [];
            for (let i = 0; i < targetUserIds.length; i += 30) {
                chunks.push(targetUserIds.slice(i, i + 30));
            }

            const promises = chunks.map(chunk =>
                admin.firestore()
                .collection("users")
                .where(admin.firestore.FieldPath.documentId(), "in", chunk)
                .get()
            );

            const snapshots = await Promise.all(promises);

            targetTokens = [];
            snapshots.forEach(snap => {
                snap.docs.forEach(doc => {
                    const token = doc.data().fcmToken;
                    if (token) {
                        targetTokens.push(token);
                    }
                });
            });
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

        // Send multicast message in batches
        let successCount = 0;
        let failureCount = 0;
        const BATCH_SIZE = 500;

        console.log(`Sending broadcast to ${targetTokens.length} tokens...`);

        for (let i = 0; i < targetTokens.length; i += BATCH_SIZE) {
            const batchTokens = targetTokens.slice(i, i + BATCH_SIZE);

            const message = {
                notification: {
                    title: title,
                    body: body,
                    ...(imageUrl && { imageUrl }),
                },
                data: customData || {},
                tokens: batchTokens,
            };

            const response = await admin.messaging().sendEachForMulticast(message);
            successCount += response.successCount;
            failureCount += response.failureCount;

             if (response.failureCount > 0) {
                console.log(`Failed to send ${response.failureCount} messages in batch ${i / BATCH_SIZE}`);
                response.responses.forEach((resp, idx) => {
                    if (!resp.success) {
                        // Log error but don't expose sensitive token info too much
                        console.error(`Error sending to token index ${idx}:`, resp.error);
                        // TODO: Handle invalid tokens (e.g. remove from DB)
                    }
                });
            }
        }

        console.log(`Total sent: ${successCount}, Total failed: ${failureCount}`);

        // Log the broadcast
        await admin.firestore().collection("broadcast_logs").add({
            title,
            body,
            targetType: targetUserIds.length > 0 ? "users" : "cities",
            targetIds: targetUserIds.length > 0 ? targetUserIds : targetCities,
            sentBy: context.auth.uid,
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
            successCount: successCount,
            failureCount: failureCount,
        });

        return {
            success: true,
            successCount: successCount,
            failureCount: failureCount,
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
