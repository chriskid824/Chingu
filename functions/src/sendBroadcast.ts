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

    // Verify that the user is an admin
    // We check if the user exists in the 'admins' collection
    const adminDoc = await admin.firestore()
        .collection("admins")
        .doc(context.auth.uid)
        .get();

    if (!adminDoc.exists) {
        // Also check if the user has custom claim 'admin'
        // This allows for flexible admin assignment
        if (context.auth.token.admin !== true) {
             throw new functions.https.HttpsError(
                "permission-denied",
                "Only admins can send broadcast notifications."
            );
        }
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
            // Chunk ids to avoid Firestore "in" query limit (10)
            const chunks = chunkArray(targetUserIds, 10);
            for (const chunk of chunks) {
                const usersSnapshot = await admin.firestore()
                    .collection("users")
                    .where(admin.firestore.FieldPath.documentId(), "in", chunk)
                    .get();

                usersSnapshot.docs.forEach((doc) => {
                    const token = doc.data().fcmToken;
                    if (token) targetTokens.push(token);
                });
            }
        } else if (targetCities && targetCities.length > 0) {
            // Send to users in specific cities
            // Chunk cities to avoid Firestore "in" query limit (10)
            const citiesLower = targetCities.map((city: string) => city.toLowerCase());
            const chunks = chunkArray(citiesLower, 10);

            for (const chunk of chunks) {
                const usersSnapshot = await admin.firestore()
                    .collection("users")
                    .where("city", "in", chunk)
                    .get();

                usersSnapshot.docs.forEach((doc) => {
                    const token = doc.data().fcmToken;
                    if (token) targetTokens.push(token);
                });
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
            throw new functions.https.HttpsError(
                "not-found",
                "No users found with FCM tokens for the specified criteria."
            );
        }

        // Send multicast messages in batches of 500
        const tokenChunks = chunkArray(targetTokens, 500);
        let totalSuccessCount = 0;
        let totalFailureCount = 0;

        for (const chunk of tokenChunks) {
            const message: admin.messaging.MulticastMessage = {
                notification: {
                    title: title,
                    body: body,
                    ...(imageUrl && { imageUrl }),
                },
                data: customData || {},
                tokens: chunk,
            };

            const response = await admin.messaging().sendEachForMulticast(message);

            totalSuccessCount += response.successCount;
            totalFailureCount += response.failureCount;

            if (response.failureCount > 0) {
                console.log(`Failed to send ${response.failureCount} messages in a batch`);
                response.responses.forEach((resp, idx) => {
                    if (!resp.success) {
                        console.error(`Error sending to token ${chunk[idx]}:`, resp.error);
                        // TODO: Handle invalid tokens (e.g. remove from Firestore)
                    }
                });
            }
        }

        console.log(`Broadcast finished. Success: ${totalSuccessCount}, Failure: ${totalFailureCount}`);

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

// Helper function to chunk array
function chunkArray<T>(array: T[], size: number): T[][] {
    const chunks: T[][] = [];
    for (let i = 0; i < array.length; i += size) {
        chunks.push(array.slice(i, i + size));
    }
    return chunks;
}
