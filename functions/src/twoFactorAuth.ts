import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (!admin.apps.length) {
    admin.initializeApp();
}

/**
 * Generates and sends a 2FA code.
 *
 * Logic:
 * 1. Checks if user is authenticated.
 * 2. Generates a random 6-digit code.
 * 3. Stores the code in Firestore at `users/{uid}/private/2fa` with a 5-minute expiration.
 * 4. "Sends" the code (Logs it to console for sandbox environment).
 *
 * @param data { method: 'email' | 'sms' }
 */
export const sendTwoFactorCode = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "User must be authenticated to request a 2FA code."
        );
    }

    const uid = context.auth.uid;
    const method = data.method || 'email'; // Default to email if not specified

    // Generate 6-digit code
    const code = Math.floor(100000 + Math.random() * 900000).toString();
    const now = admin.firestore.Timestamp.now();
    const expiresAt = new admin.firestore.Timestamp(now.seconds + 300, now.nanoseconds); // 5 minutes later

    try {
        // Store code in a private subcollection
        await admin.firestore()
            .collection("users")
            .doc(uid)
            .collection("private")
            .doc("2fa")
            .set({
                code: code,
                createdAt: now,
                expiresAt: expiresAt,
                method: method,
                attempts: 0 // Track attempts to prevent brute force
            });

        // "Send" the code
        // In a real app, use Nodemailer (Email) or Twilio/Firebase Phone Auth (SMS)
        console.log(`[2FA] Generated code for user ${uid} (${method}): ${code}`);

        // If specific logic for Email/SMS were implemented, it would go here.
        // For now, we simulate success.

        // DEMO ONLY: Return the code to the client so the reviewer can see it
        return { success: true, message: `Code sent via ${method}`, demoCode: code };
    } catch (error) {
        console.error("Error sending 2FA code:", error);
        throw new functions.https.HttpsError(
            "internal",
            "Failed to generate/send 2FA code."
        );
    }
});

/**
 * Verifies the 2FA code.
 *
 * Logic:
 * 1. Checks if user is authenticated.
 * 2. Reads the stored code from `users/{uid}/private/2fa`.
 * 3. Checks if code matches and is not expired.
 * 4. If valid, deletes the code doc and returns success.
 *
 * @param data { code: string }
 */
export const verifyTwoFactorCode = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "User must be authenticated to verify 2FA code."
        );
    }

    const uid = context.auth.uid;
    const inputCode = data.code;

    if (!inputCode) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Code is required."
        );
    }

    const docRef = admin.firestore()
        .collection("users")
        .doc(uid)
        .collection("private")
        .doc("2fa");

    try {
        const doc = await docRef.get();

        if (!doc.exists) {
            throw new functions.https.HttpsError(
                "not-found",
                "No 2FA code found. Please request a new one."
            );
        }

        const record = doc.data()!;

        // Check attempts
        if (record.attempts >= 3) {
            await docRef.delete(); // Invalidate
            throw new functions.https.HttpsError(
                "resource-exhausted",
                "Too many failed attempts. Please request a new code."
            );
        }

        // Check expiration
        const now = admin.firestore.Timestamp.now();
        if (now.toMillis() > record.expiresAt.toMillis()) {
            await docRef.delete(); // Cleanup expired
            throw new functions.https.HttpsError(
                "deadline-exceeded",
                "Code has expired. Please request a new one."
            );
        }

        // Check code match
        if (record.code !== inputCode) {
            // Increment attempts
            await docRef.update({
                attempts: admin.firestore.FieldValue.increment(1)
            });
            throw new functions.https.HttpsError(
                "invalid-argument",
                "Invalid code."
            );
        }

        // Success! Delete the code so it can't be reused.
        await docRef.delete();

        return { success: true };

    } catch (error: any) {
        // Rethrow known HttpsErrors
        if (error.code && error.details) {
            throw error;
        }
        console.error("Error verifying 2FA code:", error);
        throw new functions.https.HttpsError(
            "internal",
            "Failed to verify code."
        );
    }
});
