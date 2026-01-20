import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Initialize admin if not already initialized
if (admin.apps.length === 0) {
  admin.initializeApp();
}

/**
 * Triggers when a new 2FA verification code is created in Firestore.
 * Sends the code via Email or SMS.
 */
export const sendTwoFactorCode = functions.firestore
  .document("users/{userId}/verification_codes/current")
  .onCreate(async (snapshot, context) => {
    const data = snapshot.data();
    if (!data) {
      console.log("No data found");
      return;
    }

    const { code, method, contact } = data;
    const userId = context.params.userId;

    console.log(`Sending 2FA code to user ${userId} via ${method}`);

    try {
      if (method === "email") {
        await sendEmail(contact, code);
      } else if (method === "sms") {
        await sendSms(contact, code);
      } else {
        console.warn(`Unknown 2FA method: ${method}`);
      }
    } catch (error) {
      console.error("Error sending 2FA code:", error);
    }
  });

/**
 * Simulates sending an email.
 * In a real application, integrate with Nodemailer, SendGrid, or Firebase Extensions.
 */
async function sendEmail(email: string, code: string) {
  console.log(`[MOCK EMAIL] To: ${email}, Subject: Your Verification Code, Body: ${code}`);
  // Example Nodemailer integration (commented out):
  // const transporter = nodemailer.createTransport({ ... });
  // await transporter.sendMail({
  //   from: '"Chingu App" <noreply@chingu.app>',
  //   to: email,
  //   subject: "Your Verification Code",
  //   text: `Your verification code is: ${code}. It expires in 5 minutes.`,
  // });
  return Promise.resolve();
}

/**
 * Simulates sending an SMS.
 * In a real application, integrate with Twilio or Firebase Auth Phone.
 */
async function sendSms(phoneNumber: string, code: string) {
  console.log(`[MOCK SMS] To: ${phoneNumber}, Message: Your Chingu verification code is: ${code}`);
  return Promise.resolve();
}
