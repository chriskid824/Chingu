import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {getNotificationCopy, allNotificationTests} from "./notification_content";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

/**
 * Cloud Function to send A/B tested notifications
 *
 * Usage:
 * - notificationType: "match_success" | "new_message" | "event_reminder" | "inactivity_reminder"
 * - params: { userName: "Alice", messagePreview: "Hi..." }
 */
export const sendNotification = functions.https.onCall(async (data, context) => {
  // 1. Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  const {targetUserId, notificationType, params, data: customData} = data;

  // 2. Validate inputs
  if (!targetUserId || !notificationType) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "targetUserId and notificationType are required."
    );
  }

  try {
    // 3. Get User's FCM Token
    const userDoc = await admin.firestore().collection("users").doc(targetUserId).get();

    if (!userDoc.exists) {
      console.log(`User ${targetUserId} not found.`);
      // Not throwing error to avoid crashing caller, just return failure
      return {success: false, reason: "user_not_found"};
    }

    const userData = userDoc.data();
    const fcmToken = userData?.fcmToken;

    if (!fcmToken) {
      console.log(`No FCM token for user ${targetUserId}`);
      return {success: false, reason: "no_token"};
    }

    // 4. Determine Copy (A/B Test)
    // Find the test config for this notification type
    const testConfig = allNotificationTests.find((t) => t.notificationType === notificationType);

    let title = "Notification";
    let body = "";
    let variantId = "control"; // Default

    if (testConfig) {
      // Fetch user's variant assignment
      // We assume the client-side ABTestManager or another process has already assigned a variant.
      // If not, we fall back to default (control).
      const variantDoc = await admin.firestore()
        .collection("users")
        .doc(targetUserId)
        .collection("ab_test_variants")
        .doc(testConfig.testId)
        .get();

      if (variantDoc.exists) {
        variantId = variantDoc.data()?.variant;
      } else {
        variantId = testConfig.defaultVariantId;
      }

      // Get copy
      const copy = getNotificationCopy(testConfig.testId, variantId, params || {});
      title = copy.title;
      body = copy.body;
    } else {
      // Fallback if no test configured
      title = params?.title || "New Notification";
      body = params?.body || "You have a new notification";
    }

    // 5. Send Notification
    const message = {
      notification: {
        title,
        body,
      },
      data: {
        ...customData,
        notificationType,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        ab_test_id: testConfig?.testId || "",
        ab_variant_id: variantId,
      },
      token: fcmToken,
    };

    const response = await admin.messaging().send(message);
    console.log(`Successfully sent notification to ${targetUserId}, messageId: ${response}`);

    return {success: true, messageId: response};
  } catch (error) {
    console.error("Error sending notification:", error);
    throw new functions.https.HttpsError("internal", "Failed to send notification", error);
  }
});
