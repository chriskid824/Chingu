import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

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

    // Admin role verification
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
        }

        // Targeted notifications
        if (targetUserIds && targetUserIds.length > 0) {
            // Firestore 'in' query limit is 10 (safe limit)
            const chunks = chunkArray(targetUserIds, 10);
            for (const chunk of chunks) {
                const usersSnapshot = await admin.firestore()
                    .collection("users")
                    .where(admin.firestore.FieldPath.documentId(), "in", chunk)
                    .get();

                const tokens = usersSnapshot.docs
                    .map((doc) => doc.data().fcmToken)
                    .filter((token) => token); // Remove null/undefined tokens
                targetTokens.push(...tokens);
            }
        } else if (targetCities && targetCities.length > 0) {
            const citiesLower = targetCities.map((city: string) => city.toLowerCase());
            const chunks = chunkArray(citiesLower, 10);
            for (const chunk of chunks) {
                const usersSnapshot = await admin.firestore()
                    .collection("users")
                    .where("city", "in", chunk)
                    .get();

                const tokens = usersSnapshot.docs
                    .map((doc) => doc.data().fcmToken)
                    .filter((token) => token);
                targetTokens.push(...tokens);
            }
        } else {
             throw new functions.https.HttpsError(
                "invalid-argument",
                "Must specify targetAll, targetUserIds, or targetCities."
            );
        }

        // Deduplicate tokens
        targetTokens = [...new Set(targetTokens)];

        if (targetTokens.length === 0) {
             // It's possible to find users but they have no tokens.
             // We should just return success with 0 count.
             console.log("No FCM tokens found for targets.");
             return {
                success: true,
                successCount: 0,
                failureCount: 0,
                totalTargets: 0,
            };
        }

        // Send multicast message in chunks of 500
        const tokenChunks = chunkArray(targetTokens, 500);
        let successCount = 0;
        let failureCount = 0;
        const errors: any[] = [];

        for (const chunk of tokenChunks) {
            const message = {
                notification: {
                    title: title,
                    body: body,
                    ...(imageUrl && { imageUrl }),
                },
                data: customData || {},
                tokens: chunk,
            };

            const response = await admin.messaging().sendEachForMulticast(message);
            successCount += response.successCount;
            failureCount += response.failureCount;

            if (response.failureCount > 0) {
                response.responses.forEach((resp, idx) => {
                    if (!resp.success) {
                        errors.push({
                            token: chunk[idx],
                            error: resp.error
                        });
                        console.error(`Error sending to token ${chunk[idx]}:`, resp.error);
                    }
                });
            }
        }

        console.log(`Broadcast summary: ${successCount} success, ${failureCount} failure`);

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
            totalTokens: targetTokens.length
        });

        return {
            success: true,
            successCount,
            failureCount,
            totalTargets: targetTokens.length,
            errors: errors.slice(0, 10) // Return first 10 errors to avoid huge payload
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

function chunkArray<T>(array: T[], size: number): T[][] {
    const chunked: T[][] = [];
    for (let i = 0; i < array.length; i += size) {
        chunked.push(array.slice(i, i + size));
    }
    return chunked;
}
