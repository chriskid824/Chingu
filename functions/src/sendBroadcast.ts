import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Conditional initialization to prevent "app already exists" errors
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
    // 1. Authentication Check
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "Only authenticated users can send broadcasts."
        );
    }

    // 2. Admin Role Verification
    try {
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
    } catch (error) {
        console.error("Error verifying admin status:", error);
        throw new functions.https.HttpsError(
            "internal",
            "Error verifying permission."
        );
    }

    const {
        title,
        body,
        data: customData,
        targetAll = false,
        imageUrl,
    } = data;

    const targetCities = (data.targetCities || []) as string[];
    const targetUserIds = (data.targetUserIds || []) as string[];

    // 3. Validate Inputs
    if (!title || !body) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Title and body are required."
        );
    }

    try {
        let successCount = 0;
        let failureCount = 0;
        let targetType = "";
        let targetIds: string[] = [];

        if (targetAll) {
            targetType = "all";
            // Topic messaging
            const message: admin.messaging.Message = {
                notification: {
                    title,
                    body,
                    ...(imageUrl && { imageUrl }),
                },
                data: customData || {},
                topic: "all_users",
            };

            const response = await admin.messaging().send(message);
            console.log("Successfully sent broadcast to all users:", response);
            // Topic send returns a message ID string.
            // We assume successful delivery to the topic accepted by FCM.
            successCount = 1;

        } else {
            // Targeted messaging
            let targetTokens: string[] = [];

            if (targetUserIds && targetUserIds.length > 0) {
                targetType = "users";
                targetIds = targetUserIds;

                // Chunk queries for IDs (Firestore 'in' limit is 10)
                const chunks = chunkArray(targetUserIds, 10);
                for (const chunk of chunks) {
                     const usersSnapshot = await admin.firestore()
                        .collection("users")
                        .where(admin.firestore.FieldPath.documentId(), "in", chunk)
                        .get();

                     usersSnapshot.docs.forEach(doc => {
                         const token = doc.data().fcmToken;
                         if (token) targetTokens.push(token);
                     });
                }

            } else if (targetCities && targetCities.length > 0) {
                targetType = "cities";
                targetIds = targetCities;

                // Chunk queries for Cities (Firestore 'in' limit is 10)
                const chunks = chunkArray(targetCities, 10);
                for (const chunk of chunks) {
                    const citiesLower = chunk.map((c: string) => c.toLowerCase());
                    const usersSnapshot = await admin.firestore()
                        .collection("users")
                        .where("city", "in", citiesLower)
                        .get();

                    usersSnapshot.docs.forEach(doc => {
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

            if (targetTokens.length === 0) {
                 return {
                    success: true,
                    message: "No users found for specified targets.",
                    successCount: 0,
                    failureCount: 0
                };
            }

            // Deduplicate tokens
            targetTokens = [...new Set(targetTokens)];

            // Send in batches of 500 (FCM limit)
            const tokenChunks = chunkArray(targetTokens, 500);

            for (const chunk of tokenChunks) {
                const message: admin.messaging.MulticastMessage = {
                    notification: {
                        title,
                        body,
                        ...(imageUrl && { imageUrl }),
                    },
                    data: customData || {},
                    tokens: chunk,
                };

                const response = await admin.messaging().sendEachForMulticast(message);
                successCount += response.successCount;
                failureCount += response.failureCount;

                if (response.failureCount > 0) {
                    console.log(`Failed to send ${response.failureCount} messages in a batch`);
                    // Log errors for debugging
                    response.responses.forEach((resp, idx) => {
                        if (!resp.success) {
                            console.error(`Error sending to token ${chunk[idx]}:`, resp.error);
                        }
                    });
                }
            }
        }

        // Log the broadcast
        await admin.firestore().collection("broadcast_logs").add({
            title,
            body,
            targetType,
            // Limit stored IDs to avoid document size limits if targeting many individual users
            targetIds: targetIds.length > 1000 ? targetIds.slice(0, 1000) : targetIds,
            truncatedTargetIds: targetIds.length > 1000,
            sentBy: context.auth.uid,
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
            successCount,
            failureCount,
        });

        return {
            success: true,
            successCount,
            failureCount,
            totalTargets: targetAll ? "topic: all_users" : successCount + failureCount,
        };

    } catch (error) {
        console.error("Error sending broadcast:", error);
        if (error instanceof functions.https.HttpsError) {
            throw error;
        }
        throw new functions.https.HttpsError(
            "internal",
            "Failed to send broadcast notification.",
            error
        );
    }
});

/**
 * Helper function to chunk an array into smaller arrays
 */
function chunkArray<T>(array: T[], size: number): T[][] {
    const chunked: T[][] = [];
    for (let i = 0; i < array.length; i += size) {
        chunked.push(array.slice(i, i + size));
    }
    return chunked;
}
