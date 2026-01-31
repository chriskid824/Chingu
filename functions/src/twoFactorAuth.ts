import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Request a 2FA code.
 * Generates a 6-digit code, stores it in Firestore, and logs it (simulating sending).
 */
export const requestTwoFactorCode = functions.https.onCall(async (data, context) => {
    // 1. Auth Check
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "The user must be authenticated to request a 2FA code."
        );
    }

    const uid = context.auth.uid;
    const { method, target } = data; // method: 'email' | 'sms', target: email or phone

    if (!method || !target) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Method and target are required."
        );
    }

    // 2. Generate Code
    const code = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = admin.firestore.Timestamp.fromDate(
        new Date(Date.now() + 10 * 60 * 1000) // 10 minutes
    );

    // 3. Store in Firestore (Overwrite existing)
    try {
        await admin.firestore().collection("two_factor_codes").doc(uid).set({
            code,
            method,
            target,
            expiresAt,
            attempts: 0,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // 4. "Send" Code (Log to notification_logs)
        // In a real app, integrate SendGrid or Twilio here.
        await admin.firestore().collection("notification_logs").add({
            type: "2fa_code",
            uid,
            target,
            method,
            body: `Your verification code is: ${code}`,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        return { success: true, message: "Verification code sent." };
    } catch (error) {
        console.error("Error generating 2FA code:", error);
        throw new functions.https.HttpsError("internal", "Failed to generate code.");
    }
});

/**
 * Verify a 2FA code.
 */
export const verifyTwoFactorCode = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "The user must be authenticated to verify a 2FA code."
        );
    }

    const uid = context.auth.uid;
    const { code } = data;

    if (!code) {
        throw new functions.https.HttpsError("invalid-argument", "Code is required.");
    }

    const docRef = admin.firestore().collection("two_factor_codes").doc(uid);

    try {
        const doc = await docRef.get();

        if (!doc.exists) {
            throw new functions.https.HttpsError("not-found", "No verification code found.");
        }

        const record = doc.data()!;

        // Check Expiration
        if (record.expiresAt.toDate() < new Date()) {
            throw new functions.https.HttpsError("failed-precondition", "Code expired.");
        }

        // Check Attempts
        if (record.attempts >= 5) {
             throw new functions.https.HttpsError("resource-exhausted", "Too many failed attempts.");
        }

        // Verify
        if (record.code === code) {
            // Success: Clean up
            await docRef.delete();
            return { success: true };
        } else {
            // Failure: Increment attempts
            await docRef.update({
                attempts: admin.firestore.FieldValue.increment(1)
            });
            return { success: false, message: "Invalid code." };
        }
    } catch (error) {
        console.error("Error verifying 2FA code:", error);
        // Rethrow HttpsError if it is one, otherwise wrap
        if (error instanceof functions.https.HttpsError) {
             throw error;
        }
        throw new functions.https.HttpsError("internal", "Verification failed.");
    }
});
