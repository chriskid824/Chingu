import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as crypto from "crypto";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();

// Collection name
const COLLECTION = "two_factor_codes";

/**
 * Sends a verification code via SMS or Email
 *
 * @param data.target - Email address or phone number
 * @param data.method - 'email' or 'sms'
 * @param data.uid - Optional user ID
 */
export const sendVerificationCode = functions.https.onCall(async (data, context) => {
  const { target, method, uid } = data;

  if (!target || !method) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Target and method are required."
    );
  }

  if (method !== "email" && method !== "sms") {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Method must be 'email' or 'sms'."
    );
  }

  try {
    // 1. Generate 6-digit code securely
    const code = crypto.randomInt(100000, 1000000).toString();

    // 2. Set expiration (10 minutes)
    const expiresAt = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() + 10 * 60 * 1000)
    );

    // 3. Store in Firestore (Admin SDK)
    await db.collection(COLLECTION).doc(target).set({
      code: code,
      method: method,
      expiresAt: expiresAt,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      uid: uid || null,
      attempts: 0,
    });

    // 4. "Send" the code (Mock implementation)
    // In a real application, you would use Twilio (SMS) or SendGrid (Email) here.
    console.log(`[MOCK] Sending ${method} to ${target}: ${code}`);

    // Log for debugging/audit
    console.log(`Generated 2FA code for ${target} (${method})`);

    return { success: true, message: "Verification code sent." };

  } catch (error) {
    console.error("Error sending verification code:", error);
    throw new functions.https.HttpsError(
      "internal",
      "Failed to send verification code.",
      error
    );
  }
});

/**
 * Verifies the provided code
 *
 * @param data.target - Email address or phone number
 * @param data.code - The code to verify
 */
export const verifyVerificationCode = functions.https.onCall(async (data, context) => {
  const { target, code } = data;

  if (!target || !code) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Target and code are required."
    );
  }

  const docRef = db.collection(COLLECTION).doc(target);

  try {
    await db.runTransaction(async (transaction) => {
      const doc = await transaction.get(docRef);

      if (!doc.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          "Verification code not found or expired."
        );
      }

      const record = doc.data();
      if (!record) {
         throw new functions.https.HttpsError(
          "not-found",
          "Verification code data is empty."
        );
      }

      const expiresAt = record.expiresAt.toDate();
      const savedCode = record.code;
      const attempts = record.attempts || 0;

      // Check expiration
      if (new Date() > expiresAt) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "Verification code has expired."
        );
      }

      // Check attempts
      if (attempts >= 5) {
         throw new functions.https.HttpsError(
          "resource-exhausted",
          "Too many failed attempts. Please request a new code."
        );
      }

      // Verify code
      if (savedCode === code) {
        // Success! Delete the code to prevent reuse.
        transaction.delete(docRef);
      } else {
        // Failed. Increment attempts.
        transaction.update(docRef, {
          attempts: admin.firestore.FieldValue.increment(1),
        });

        throw new functions.https.HttpsError(
          "invalid-argument",
          "Invalid verification code."
        );
      }
    });

    return { success: true, message: "Verification successful." };

  } catch (error) {
    // If it's already an HttpsError, rethrow it
    // The transaction runner might wrap errors, but Firebase Functions usually propagates HttpsError
    if (error instanceof functions.https.HttpsError) {
        throw error;
    }
    console.error("Error verifying code:", error);
    throw new functions.https.HttpsError(
      "internal",
      "Failed to verify code.",
      error
    );
  }
});
