import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

// Ensure Firebase Admin is initialized
if (admin.apps.length === 0) {
  admin.initializeApp();
}

/**
 * Verifies a Two-Factor Authentication (2FA) code.
 *
 * This function is designed to be called directly from the client app.
 * It retrieves the stored code from Firestore (which should not be readable by the client)
 * and compares it with the user-provided code.
 *
 * @param request - The request object containing:
 *   - target: The verification target (e.g., email or phone number) used as the key.
 *   - code: The 6-digit code entered by the user.
 *   - userId: Optional user ID for logging/auditing.
 *
 * @returns { success: boolean, message: string }
 */
export const verifyTwoFactorCode = onCall(async (request) => {
  const { target, code, userId } = request.data;

  // 1. Input Validation
  if (!target || typeof target !== "string") {
    throw new HttpsError(
      "invalid-argument",
      "The function must be called with a valid 'target' (email or phone)."
    );
  }

  if (!code || typeof code !== "string") {
    throw new HttpsError(
      "invalid-argument",
      "The function must be called with a 'code'."
    );
  }

  try {
    const db = admin.firestore();
    const docRef = db.collection("two_factor_codes").doc(target);
    const doc = await docRef.get();

    // 2. Check if code exists
    if (!doc.exists) {
      throw new HttpsError(
        "not-found",
        "Verification code not found or expired."
      );
    }

    const data = doc.data();
    if (!data) {
        throw new HttpsError("internal", "Document data is empty.");
    }

    const savedCode = data.code;
    const expiresAt = data.expiresAt.toDate(); // Firestore Timestamp to Date
    const attempts = data.attempts || 0;

    // 3. Check Expiration
    if (new Date() > expiresAt) {
      // Clean up expired code
      await docRef.delete();
      throw new HttpsError("deadline-exceeded", "Verification code has expired.");
    }

    // 4. Check Attempts (Security)
    if (attempts >= 5) {
      // Too many attempts, maybe delete or just block
      // Deleting forces a new send
      await docRef.delete();
      throw new HttpsError(
        "resource-exhausted",
        "Too many failed attempts. Please request a new code."
      );
    }

    // 5. Verify Code
    if (savedCode === code) {
      // Success: Delete the code so it cannot be reused
      await docRef.delete();

      // Log success if needed
      console.log(`2FA Success for target: ${target}, userId: ${userId || 'unknown'}`);

      return { success: true, message: "Verification successful." };
    } else {
      // Failure: Increment attempts
      await docRef.update({
        attempts: admin.firestore.FieldValue.increment(1),
      });

      throw new HttpsError(
        "invalid-argument",
        "Invalid verification code."
      );
    }

  } catch (error) {
    console.error("verifyTwoFactorCode error:", error);
    // Re-throw HttpsErrors, wrap others
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError("internal", "An internal error occurred.");
  }
});
