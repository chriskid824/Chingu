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

    try {
        let targetTokens: string[] = [];
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
                data: customData || {},
                topic: "all_users",
            };

            const response = await admin.messaging().send(message);
            console.log("Successfully sent broadcast to all users:", response);

            // For topics, we don't get success/failure counts per user, so we just log the message ID
            successCount = 1; // Considered 1 success (the topic send itself)

        } else if (targetUserIds && targetUserIds.length > 0) {
            // Send to specific users using getAll for efficiency and avoiding IN query limits
            // Note: getAll supports a large number of documents but verify argument limits if array is massive
            const refs = targetUserIds.map((id: string) => admin.firestore().collection("users").doc(id));
            const usersSnapshots = await admin.firestore().getAll(...refs);

            targetTokens = usersSnapshots
                .map((doc) => doc.data()?.fcmToken)
                .filter((token) => token); // Remove null/undefined tokens

        } else if (targetCities && targetCities.length > 0) {
            // Send to users in specific cities
            if (targetCities.length > 10) {
                 throw new functions.https.HttpsError(
                    "invalid-argument",
                    "Cannot target more than 10 cities at once due to Firestore query limits."
                );
            }

            const usersSnapshot = await admin.firestore()
                .collection("users")
                .where("city", "in", targetCities)
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

        // Send multicast if we have tokens (for targeted)
        if (!targetAll) {
            if (targetTokens.length === 0) {
                // It's possible to have valid targets but no tokens (users haven't enabled notifications)
                console.log("No FCM tokens found for the specified targets.");
            } else {
                const message: admin.messaging.MulticastMessage = {
                    notification: {
                        title: title,
                        body: body,
                        ...(imageUrl && { imageUrl }),
                    },
                    data: customData || {},
                    tokens: targetTokens,
                };

                const response = await admin.messaging().sendEachForMulticast(message);

                successCount = response.successCount;
                failureCount = response.failureCount;

                console.log(`Successfully sent ${response.successCount} messages`);
                if (response.failureCount > 0) {
                    console.log(`Failed to send ${response.failureCount} messages`);
                    response.responses.forEach((resp, idx) => {
                        if (!resp.success) {
                            console.error(`Error sending to token ${targetTokens[idx]}:`, resp.error);
                        }
                    });
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
            totalTargets: targetAll ? "topic" : targetTokens.length,
        });

        return {
            success: true,
            successCount,
            failureCount,
            totalTargets: targetAll ? "all" : targetTokens.length,
        };
    } catch (error) {
        console.error("Error sending broadcast:", error);
        // If it's already an HttpsError, rethrow it
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
