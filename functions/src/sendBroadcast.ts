import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// admin.initializeApp() is handled in index.ts

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
            // Firestore 的 "in" 上限 30 個,超過必須分批查
            for (let i = 0; i < targetUserIds.length; i += 30) {
                const idChunk = targetUserIds.slice(i, i + 30);
                const usersSnapshot = await admin.firestore()
                    .collection("users")
                    .where(admin.firestore.FieldPath.documentId(), "in", idChunk)
                    .get();
                targetTokens.push(
                    ...usersSnapshot.docs
                        .map((doc) => doc.data().fcmToken)
                        .filter((token) => token)
                );
            }
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

        // Send multicast message (FCM 上限 500 token/次,分批送)
        let successCount = 0;
        let failureCount = 0;
        for (let i = 0; i < targetTokens.length; i += 500) {
            const tokenChunk = targetTokens.slice(i, i + 500);
            const response = await admin.messaging().sendEachForMulticast({
                notification: {
                    title: title,
                    body: body,
                    ...(imageUrl && { imageUrl }),
                },
                data: customData || {},
                tokens: tokenChunk,
            });
            successCount += response.successCount;
            failureCount += response.failureCount;
            response.responses.forEach((resp, idx) => {
                if (!resp.success) {
                    console.error(`Error sending to token ${tokenChunk[idx]}:`, resp.error);
                }
            });
        }

        console.log(`Successfully sent ${successCount} messages`);
        if (failureCount > 0) {
            console.log(`Failed to send ${failureCount} messages`);
        }
        const response = { successCount, failureCount };

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
