import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Ensure Firebase Admin is initialized
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

    const db = admin.firestore();

    // Verify admin role
    const adminDoc = await db.collection("admins").doc(context.auth.uid).get();
    if (!adminDoc.exists) {
        throw new functions.https.HttpsError(
            "permission-denied",
            "Only admins can send broadcast notifications."
        );
    }

    const {
        title,
        body,
        data: rawCustomData,
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

    // Ensure all custom data values are strings (FCM requirement)
    const customData: Record<string, string> = {};
    if (rawCustomData) {
        for (const [key, value] of Object.entries(rawCustomData)) {
            customData[key] = String(value);
        }
    }

    try {
        let response;
        let recipientCount = 0;
        let successCount = 0;
        let failureCount = 0;

        if (targetAll) {
            // Send to all users - use topic subscription
            const message: admin.messaging.Message = {
                notification: {
                    title: title,
                    body: body,
                    ...(imageUrl && { imageUrl }),
                },
                data: customData,
                topic: "all_users",
            };

            const msgId = await admin.messaging().send(message);
            console.log("Successfully sent broadcast to all users:", msgId);

            response = { success: true, messageId: msgId, recipients: "all" };
            recipientCount = -1; // Unknown
            successCount = -1;
        } else {
            let targetTokens: string[] = [];

            if (targetUserIds && targetUserIds.length > 0) {
                // Fetch specific users by ID using getAll to avoid 'in' query limits
                // getAll accepts varargs, so we spread the array of references
                const userRefs = targetUserIds.map((uid: string) => db.collection("users").doc(uid));

                // Firestore getAll might fail if too many arguments (thousands).
                // For reasonable admins usage, this should be fine.
                // If vast numbers needed, should use topic or batching.
                const userDocs = await db.getAll(...userRefs);

                targetTokens = userDocs
                    .map(doc => doc.data()?.fcmToken)
                    .filter(token => !!token);

            } else if (targetCities && targetCities.length > 0) {
                // Send to users in specific cities
                // 'in' query is limited to 30 items. Batch if necessary.
                const citiesLower = targetCities.map((city: string) => city.toLowerCase());
                const chunkSize = 30;

                for (let i = 0; i < citiesLower.length; i += chunkSize) {
                    const chunk = citiesLower.slice(i, i + chunkSize);
                    const usersSnapshot = await db.collection("users")
                        .where("city", "in", chunk)
                        .get();

                    const chunkTokens = usersSnapshot.docs
                        .map(doc => doc.data().fcmToken)
                        .filter(token => !!token);

                    targetTokens = targetTokens.concat(chunkTokens);
                }
            } else {
                throw new functions.https.HttpsError(
                    "invalid-argument",
                    "Must specify targetAll, targetUserIds, or targetCities."
                );
            }

            if (targetTokens.length === 0) {
                // It's possible no users matched or none had tokens.
                // We shouldn't throw error if the operation was valid but yielded no targets,
                // but usually the admin wants to know.
                console.log("No valid FCM tokens found for targets.");
                return {
                    success: true,
                    successCount: 0,
                    failureCount: 0,
                    totalTargets: 0,
                    message: "No users with FCM tokens found."
                };
            }

            // Deduplicate tokens
            targetTokens = [...new Set(targetTokens)];
            recipientCount = targetTokens.length;

            // Send multicast message
            // admin.messaging().sendEachForMulticast sends to up to 500 tokens at a time automatically
            const message: admin.messaging.MulticastMessage = {
                notification: {
                    title: title,
                    body: body,
                    ...(imageUrl && { imageUrl }),
                },
                data: customData,
                tokens: targetTokens,
            };

            const multicastResponse = await admin.messaging().sendEachForMulticast(message);

            successCount = multicastResponse.successCount;
            failureCount = multicastResponse.failureCount;

            if (failureCount > 0) {
                console.log(`Failed to send ${failureCount} messages`);
                multicastResponse.responses.forEach((resp, idx) => {
                    if (!resp.success) {
                        console.error(`Error sending to token ${targetTokens[idx]}:`, resp.error);
                    }
                });
            }

            response = {
                success: true,
                successCount,
                failureCount,
                totalTargets: recipientCount,
            };
        }

        // Log the broadcast
        await db.collection("broadcast_logs").add({
            title,
            body,
            targetType: targetAll ? "all" : (targetUserIds.length > 0 ? "users" : "cities"),
            targetIds: targetAll ? [] : (targetUserIds.length > 0 ? targetUserIds : targetCities),
            sentBy: context.auth.uid,
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
            successCount: successCount,
            failureCount: failureCount,
            recipientCount: recipientCount,
            data: customData
        });

        return response;

    } catch (error) {
        console.error("Error sending broadcast:", error);
        throw new functions.https.HttpsError(
            "internal",
            "Failed to send broadcast notification.",
            error
        );
    }
});
