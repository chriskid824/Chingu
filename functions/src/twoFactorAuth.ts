import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Ensure admin is initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

/**
 * Sends a Two-Factor Authentication email to the user.
 *
 * Note: In this demo environment, it logs the code to the Cloud Functions console
 * instead of sending a real email, unless an email provider is configured.
 */
export const sendTwoFactorEmail = functions.https.onCall(async (data, context) => {
  // 1. Check authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  const uid = context.auth.uid;
  const userEmail = context.auth.token.email;

  if (!userEmail) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "User does not have an email address."
    );
  }

  // 2. Generate 6-digit code
  const code = Math.floor(100000 + Math.random() * 900000).toString();
  const expiresAt = Date.now() + 5 * 60 * 1000; // 5 minutes from now

  try {
    // 3. Store code in Firestore (using a sub-collection for private data)
    // Using a separate collection or sub-collection ensures it's not exposed to public read
    await admin.firestore()
      .collection("users")
      .doc(uid)
      .collection("private_data")
      .doc("2fa_code")
      .set({
        code: code,
        expiresAt: expiresAt,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    // 4. Send Email (Simulated)
    // In a real app, use SendGrid, Mailgun, or Firebase Extensions
    console.log(`[2FA] Code for user ${uid} (${userEmail}): ${code}`);

    // Return success
    return { success: true, message: "Verification code sent." };
  } catch (error) {
    console.error("Error sending 2FA code:", error);
    throw new functions.https.HttpsError(
      "internal",
      "Unable to send verification code."
    );
  }
});

/**
 * Verifies the Two-Factor Authentication code provided by the user.
 */
export const verifyTwoFactorEmail = functions.https.onCall(async (data, context) => {
  // 1. Check authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  const uid = context.auth.uid;
  const inputCode = data.code;

  if (!inputCode) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "The function must be called with a 'code' argument."
    );
  }

  try {
    // 2. Retrieve stored code
    const docSnap = await admin.firestore()
      .collection("users")
      .doc(uid)
      .collection("private_data")
      .doc("2fa_code")
      .get();

    if (!docSnap.exists) {
      return { success: false, message: "No verification code found. Please request a new one." };
    }

    const record = docSnap.data();

    if (!record) {
        return { success: false, message: "Invalid record." };
    }

    // 3. Check expiration
    if (Date.now() > record.expiresAt) {
      return { success: false, message: "Verification code has expired." };
    }

    // 4. Verify code
    if (record.code === inputCode) {
      // Success!
      // Optionally clean up the code to prevent reuse
      await docSnap.ref.delete();

      return { success: true };
    } else {
      return { success: false, message: "Invalid verification code." };
    }

  } catch (error) {
    console.error("Error verifying 2FA code:", error);
    throw new functions.https.HttpsError(
      "internal",
      "Unable to verify code."
    );
  }
});
