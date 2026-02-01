import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (!admin.apps.length) {
    admin.initializeApp();
}

/**
 * Request 2FA Code
 *
 * Generates a code and sends it via the specified method.
 * Data: { method: 'email' | 'sms', target: string }
 */
export const requestTwoFactorCode = functions.https.onCall(async (data, context) => {
    // Verify Authentication
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "User must be authenticated to request 2FA code."
        );
    }

    const uid = context.auth.uid;
    const { method, target } = data;

    if (!method || !['email', 'sms'].includes(method)) {
        throw new functions.https.HttpsError("invalid-argument", "Invalid method. Must be 'email' or 'sms'.");
    }

    if (!target) {
        throw new functions.https.HttpsError("invalid-argument", "Target (email or phone) is required.");
    }

    // 2. Generate Code
    const code = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = admin.firestore.Timestamp.fromMillis(Date.now() + 10 * 60 * 1000); // 10 mins

    // 3. Store in Firestore (Admin access only)
    // We use UID as document ID to ensure only one active code per user
    await admin.firestore().collection("two_factor_codes").doc(uid).set({
        code,
        method,
        target,
        expiresAt,
        attempts: 0,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // 4. Send Code (Mock)
    console.log(`[2FA-MOCK] Sending ${method} to ${target} with code: ${code}`);

    // In a real implementation, you would call:
    // if (method === 'email') await sendEmail(target, code);
    // if (method === 'sms') await sendSms(target, code);

    return { success: true, message: "Verification code sent." };
});

/**
 * Verify 2FA Code
 *
 * Data: { code: string }
 */
export const verifyTwoFactorCode = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "User must be authenticated to verify 2FA code."
        );
    }

    const uid = context.auth.uid;
    const { code } = data;

    if (!code) {
        throw new functions.https.HttpsError("invalid-argument", "Code is required.");
    }

    const docRef = admin.firestore().collection("two_factor_codes").doc(uid);
    const doc = await docRef.get();

    if (!doc.exists) {
        throw new functions.https.HttpsError("not-found", "No pending verification code.");
    }

    const record = doc.data();
    if (!record) {
        throw new functions.https.HttpsError("internal", "Record is empty.");
    }

    if (record.attempts >= 5) {
        await docRef.delete();
        throw new functions.https.HttpsError("resource-exhausted", "Too many failed attempts. Please request a new code.");
    }

    if (Date.now() > record.expiresAt.toMillis()) {
        await docRef.delete();
        throw new functions.https.HttpsError("deadline-exceeded", "Verification code expired.");
    }

    if (record.code !== code) {
        await docRef.update({ attempts: admin.firestore.FieldValue.increment(1) });
        throw new functions.https.HttpsError("invalid-argument", "Invalid verification code.");
    }

    // Success
    await docRef.delete();

    return { success: true };
});
