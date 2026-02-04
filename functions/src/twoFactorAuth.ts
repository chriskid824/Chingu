import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as crypto from "crypto";

// Ensure admin is initialized
if (admin.apps.length === 0) {
  admin.initializeApp();
}

/**
 * Generates a 6-digit code and stores it in Firestore with an expiration time.
 * In a real-world scenario, this would send an SMS or Email via a provider (e.g., Twilio, SendGrid).
 * Here, we log the code to the console for simulation.
 */
export const sendTwoFactorCode = functions.https.onCall(async (data, context) => {
  // 1. Verify Authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "The function must be called while authenticated."
    );
  }

  const userId = context.auth.uid;
  const method = data.method || "email"; // 'email' or 'sms'

  // 2. Generate Secure Code
  // Generate a random integer between 100000 and 999999 (inclusive)
  const code = crypto.randomInt(100000, 1000000).toString();
  const expiresAt = admin.firestore.Timestamp.fromMillis(Date.now() + 5 * 60 * 1000); // 5 minutes

  // 3. Store in Firestore (Securely)
  await admin.firestore()
      .collection("users")
      .doc(userId)
      .collection("private")
      .doc("2fa")
      .set({
        code: code,
        expiresAt: expiresAt,
        method: method,
        attempts: 0,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

  // 4. Send Code (Simulation)
  // WARNING: In production, do not log sensitive codes. This is for simulation purposes only.
  console.log(`[2FA_SIMULATION] Sending verification code ${code} to user ${userId} via ${method}.`);

  return { success: true, message: `Code sent via ${method}` };
});

/**
 * Verifies the provided 2FA code against the stored code in Firestore.
 */
export const verifyTwoFactorCode = functions.https.onCall(async (data, context) => {
  // 1. Verify Authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "The function must be called while authenticated."
    );
  }

  const userId = context.auth.uid;
  const inputCode = data.code;

  if (!inputCode) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "The function must be called with a 'code' argument."
    );
  }

  // 2. Retrieve Code from Firestore
  const docRef = admin.firestore()
      .collection("users")
      .doc(userId)
      .collection("private")
      .doc("2fa");

  const snapshot = await docRef.get();

  if (!snapshot.exists) {
    return { valid: false, message: "No code found. Please request a new one." };
  }

  const dataStored = snapshot.data();
  if (!dataStored) {
    return { valid: false, message: "Invalid data." };
  }

  const storedCode = dataStored.code;
  const expiresAt = dataStored.expiresAt;
  const attempts = dataStored.attempts || 0;

  // 3. Check Attempts
  if (attempts >= 3) {
    // Too many failed attempts - invalidate the code
    await docRef.delete();
    return { valid: false, message: "Too many failed attempts. Code invalidated." };
  }

  // 4. Check Expiration
  const now = admin.firestore.Timestamp.now();
  if (now > expiresAt) {
    // Clean up expired code
    await docRef.delete();
    return { valid: false, message: "Code expired." };
  }

  // 5. Check Match
  if (storedCode !== inputCode) {
    // Increment attempts
    await docRef.update({
      attempts: admin.firestore.FieldValue.increment(1)
    });
    return { valid: false, message: "Invalid code." };
  }

  // 6. Success - Clear the code to prevent reuse
  await docRef.delete();

  return { valid: true };
});
