import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Guarded initialization
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

    // Verify admin role
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
        let successCount = 0;
        let failureCount = 0;
        let totalTargets = 0;

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
            successCount = 1; // 1 topic message sent
            totalTargets = 1; // conceptual target
        } else {
            let targetTokens: string[] = [];

            if (targetUserIds && targetUserIds.length > 0) {
                // Send to specific users
                // Use getAll to avoid "in" query limit of 10
                const userRefs = targetUserIds.map((id: string) =>
                    admin.firestore().collection("users").doc(id)
                );

                // Fetch in batches if necessary, but getAll handles multiple docs.
                // Assuming targetUserIds size is reasonable for a callable function argument.
                const userDocs = await admin.firestore().getAll(...userRefs);

                targetTokens = userDocs
                    .map((doc) => doc.data()?.fcmToken)
                    .filter((token) => token); // Remove null/undefined tokens

            } else if (targetCities && targetCities.length > 0) {
                // Send to users in specific cities
                // Chunk cities into groups of 10 for "in" query
                const citiesLower = targetCities.map((city: string) => city.toLowerCase());
                const chunks = [];
                for (let i = 0; i < citiesLower.length; i += 10) {
                    chunks.push(citiesLower.slice(i, i + 10));
                }

                const promises = chunks.map(chunk =>
                    admin.firestore()
                        .collection("users")
                        .where("city", "in", chunk)
                        .get()
                );

                const snapshots = await Promise.all(promises);

                // Merge tokens using Set to avoid duplicates (though rare unless user moves/duplicate?)
                const seenTokens = new Set<string>();
                snapshots.forEach(snap => {
                    snap.docs.forEach(doc => {
                        const token = doc.data().fcmToken;
                        if (token) seenTokens.add(token);
                    });
                });

                targetTokens = Array.from(seenTokens);

            } else {
                throw new functions.https.HttpsError(
                    "invalid-argument",
                    "Must specify targetAll, targetUserIds, or targetCities."
                );
            }

            if (targetTokens.length === 0) {
                console.log("No valid FCM tokens found for the targets.");
                return { success: true, message: "No targets found with tokens.", count: 0 };
            }

            totalTargets = targetTokens.length;

            // Batch send multicast (limit 500 per batch)
            const tokenChunks = [];
            for (let i = 0; i < targetTokens.length; i += 500) {
                tokenChunks.push(targetTokens.slice(i, i + 500));
            }

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
                successCount += response.successCount;
                failureCount += response.failureCount;

                if (response.failureCount > 0) {
                    console.log(`Batch had ${response.failureCount} failures.`);
                }
            }
        }

        // Log the broadcast
        await admin.firestore().collection("broadcast_logs").add({
            title,
            body,
            targetType: targetAll ? "all" : (targetUserIds.length > 0 ? "users" : "cities"),
            targetIds: targetAll ? null : (targetUserIds.length > 0 ? targetUserIds : targetCities),
            sentBy: context.auth.uid,
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
            successCount,
            failureCount,
            totalTargets,
        });

        return {
            success: true,
            successCount,
            failureCount,
            totalTargets,
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
