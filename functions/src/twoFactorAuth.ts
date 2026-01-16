import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as crypto from "crypto";

if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * Cloud Function to send a 2FA verification code.
 * Generates a 6-digit code, stores it in Firestore, and "sends" it (logs it).
 *
 * Data params:
 * - target: string (Email or Phone Number)
 * - method: string ('email' or 'sms')
 */
export const sendTwoFactorCode = functions.https.onCall(async (data, context) => {
    const { target, method } = data;

    if (!target || !method) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Target and method are required."
        );
    }

    // Generate 6-digit code securely
    const code = crypto.randomInt(100000, 1000000).toString();
    const expiresAt = admin.firestore.Timestamp.fromDate(
        new Date(Date.now() + 10 * 60 * 1000) // 10 minutes
    );

    // Hash the target to use as document ID (privacy & safety)
    const targetHash = crypto.createHash("sha256").update(target).digest("hex");

    try {
        await admin.firestore().collection("two_factor_codes").doc(targetHash).set({
            code: code, // In production, hash this too before storing!
            method: method,
            expiresAt: expiresAt,
            attempts: 0,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Mock sending
        console.log(`[MOCK SEND] Sending 2FA code ${code} to ${target} via ${method}`);

        return { success: true };
    } catch (error) {
        console.error("Error sending 2FA code:", error);
        throw new functions.https.HttpsError(
            "internal",
            "Failed to send verification code."
        );
    }
});

/**
 * Cloud Function to verify a 2FA verification code.
 *
 * Data params:
 * - target: string
 * - code: string
 */
export const verifyTwoFactorCode = functions.https.onCall(async (data, context) => {
    const { target, code } = data;

    if (!target || !code) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Target and code are required."
        );
    }

    const targetHash = crypto.createHash("sha256").update(target).digest("hex");
    const docRef = admin.firestore().collection("two_factor_codes").doc(targetHash);

    try {
        return await admin.firestore().runTransaction(async (transaction) => {
            const doc = await transaction.get(docRef);

            if (!doc.exists) {
                return { success: false, message: "Code expired or invalid." };
            }

            const data = doc.data();
            if (!data) {
                 return { success: false, message: "Invalid data." };
            }

            const expiresAt = data.expiresAt.toDate();
            const savedCode = data.code;
            const attempts = data.attempts || 0;

            if (new Date() > expiresAt) {
                transaction.delete(docRef);
                return { success: false, message: "Code expired." };
            }

            if (attempts >= 5) {
                transaction.delete(docRef);
                return { success: false, message: "Too many attempts. Please request a new code." };
            }

            if (savedCode === code) {
                // Success
                transaction.delete(docRef);
                return { success: true };
            } else {
                // Increment attempts
                transaction.update(docRef, {
                    attempts: attempts + 1
                });
                return { success: false, message: "Invalid code." };
            }
        });

    } catch (error) {
        console.error("Error verifying 2FA code:", error);
        throw new functions.https.HttpsError(
            "internal",
            "Failed to verify code."
        );
    }
});
