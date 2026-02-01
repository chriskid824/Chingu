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
    // 1. Authentication Check
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "Only authenticated users can send broadcasts."
        );
    }

    // 2. Admin Verification
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
            "Failed to verify admin status."
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

    // 3. Validation
    if (!title || !body) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Title and body are required."
        );
    }

    if (!targetAll && (!targetCities || targetCities.length === 0) && (!targetUserIds || targetUserIds.length === 0)) {
         throw new functions.https.HttpsError(
            "invalid-argument",
            "Must specify targetAll, targetCities, or targetUserIds."
        );
    }

    try {
        let targetTokens: string[] = [];

        // 4. Token Retrieval
        if (targetAll) {
            // Fetch all users
            // Note: For very large user bases, this should be paginated or use a different strategy (like topic subscription)
            // But since clients don't subscribe to 'all_users' topic yet, we must fetch tokens.
            const usersSnapshot = await admin.firestore().collection("users").get();
            targetTokens = usersSnapshot.docs
                .map((doc) => doc.data().fcmToken)
                .filter((token) => token && typeof token === 'string' && token.length > 0);

            console.log(`Targeting all users. Found ${targetTokens.length} tokens.`);

        } else if (targetUserIds && targetUserIds.length > 0) {
            // Fetch specific users by ID
            // Firestore 'in' query is limited to 10 (or 30 in some SDKs), so we fetch by ID individually or in chunks if needed.
            // For simplicity and robustness, we can fetch all documents if list is small, or use getAll.
            // admin.firestore().getAll(...refs) is efficient.

            const refs = targetUserIds.map((id: string) => admin.firestore().collection("users").doc(id));
            const userDocs = await admin.firestore().getAll(...refs);

            targetTokens = userDocs
                .map((doc) => doc.data()?.fcmToken)
                .filter((token) => token && typeof token === 'string' && token.length > 0);

            console.log(`Targeting ${targetUserIds.length} users. Found ${targetTokens.length} tokens.`);

        } else if (targetCities && targetCities.length > 0) {
            // Fetch users by city
            // 'in' query supports up to 10 values.
            if (targetCities.length > 10) {
                throw new functions.https.HttpsError(
                    "invalid-argument",
                    "Cannot target more than 10 cities at once."
                );
            }

            const citiesLower = targetCities.map((city: string) => city.toLowerCase());
            const usersSnapshot = await admin.firestore()
                .collection("users")
                .where("city", "in", citiesLower)
                .get();

            targetTokens = usersSnapshot.docs
                .map((doc) => doc.data().fcmToken)
                .filter((token) => token && typeof token === 'string' && token.length > 0);

             console.log(`Targeting cities ${targetCities.join(', ')}. Found ${targetTokens.length} tokens.`);
        }

        if (targetTokens.length === 0) {
            console.log("No valid tokens found for the target.");
            return {
                success: true,
                successCount: 0,
                failureCount: 0,
                totalTargets: 0,
                message: "No users found to send notification to."
            };
        }

        // Deduplicate tokens
        targetTokens = [...new Set(targetTokens)];

        // 5. Batch Sending
        const BATCH_SIZE = 500;
        let successCount = 0;
        let failureCount = 0;

        // Process in batches
        for (let i = 0; i < targetTokens.length; i += BATCH_SIZE) {
            const batchTokens = targetTokens.slice(i, i + BATCH_SIZE);

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
            successCount += response.successCount;
            failureCount += response.failureCount;

            // Log failures for debugging (optional, avoid spamming logs if massive failures)
             if (response.failureCount > 0) {
                console.log(`Batch ${i/BATCH_SIZE + 1} had ${response.failureCount} failures.`);
                // Could implement logic here to remove invalid tokens from Firestore
            }
        }

        // 6. Logging
        await admin.firestore().collection("broadcast_logs").add({
            title,
            body,
            targetType: targetAll ? "all" : (targetUserIds.length > 0 ? "users" : "cities"),
            targetCount: targetTokens.length,
            sentBy: context.auth.uid,
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
            successCount: successCount,
            failureCount: failureCount,
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
