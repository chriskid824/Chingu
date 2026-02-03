# iOS Push Notification Configuration Guide

This guide outlines the steps required to fully configure iOS Push Notifications for the Chingu app. Some steps involve the Apple Developer Portal and Firebase Console, which must be done manually.

## Prerequisites
- An Apple Developer Account.
- Access to the Firebase Console project.
- A Mac with Xcode installed (for the final verification step).

## Step 1: Create APNs SSL Certificate

1.  **Generate a Certificate Signing Request (CSR):**
    *   Open **Keychain Access** on your Mac.
    *   Go to **Keychain Access > Certificate Assistant > Request a Certificate From a Certificate Authority**.
    *   Enter your email address and a Common Name (e.g., "Chingu Push Cert").
    *   Select **Saved to disk** and click **Continue**. Save the `.certSigningRequest` file.

2.  **Create the Certificate in Apple Developer Portal:**
    *   Log in to the [Apple Developer Portal](https://developer.apple.com/account).
    *   Go to **Certificates, Identifiers & Profiles**.
    *   Click **Identifiers** and locate the App ID for Chingu (`com.yourcompany.chingu` or similar). Ensure "Push Notifications" capability is checked for this App ID.
    *   Go to **Certificates** and click the **+** button.
    *   Select **Apple Push Notification service SSL (Sandbox & Production)**.
    *   Select the Chingu App ID from the dropdown.
    *   Upload the CSR file you created earlier.
    *   Download the generated certificate (`aps.cer`) and double-click it to install it into Keychain Access.

3.  **Export the .p12 File:**
    *   In **Keychain Access**, locate the certificate you just installed (usually under "My Certificates").
    *   Right-click the certificate (make sure to select the certificate, not just the private key, though expanding it shows the key) and select **Export**.
    *   Save it as a `.p12` file (e.g., `chingu_apns.p12`).
    *   You may be asked to set a password for the file. Remember this password.

## Step 2: Upload to Firebase Console

1.  Go to the [Firebase Console](https://console.firebase.google.com/).
2.  Open your project and click the **gear icon** > **Project settings**.
3.  Go to the **Cloud Messaging** tab.
4.  Scroll down to the **Apple app configuration** section.
5.  Click **Upload** under **APNs Authentication Key** (recommended if you have a Key) or **APNs Certificates**.
    *   *Note: Using an APNs Authentication Key (.p8) is often easier as it lasts forever and works for all apps, but if you created a Certificate (.p12) in Step 1, upload that.*
6.  If uploading the **Certificate (.p12)**:
    *   Browse for the `chingu_apns.p12` file.
    *   Enter the password you set (if any).
    *   Click **Upload**.

## Step 3: Verify Xcode Configuration

1.  Open the project in Xcode:
    ```bash
    open ios/Runner.xcworkspace
    ```
2.  Select the **Runner** project in the left navigator.
3.  Select the **Runner** target.
4.  Go to the **Signing & Capabilities** tab.
5.  Ensure **Push Notifications** capability is present.
    *   If not, click **+ Capability** and double-click **Push Notifications**.
6.  Ensure **Background Modes** capability is present and the following are checked:
    *   **Remote notifications**
    *   **Background fetch**
    *   *(These were automatically added to Info.plist by the setup script, but verifying in Xcode is good practice).*
7.  **Note on AppDelegate**: You do **not** need to modify `AppDelegate.swift` to handle notifications. The `firebase_messaging` plugin handles the `UNUserNotificationCenterDelegate` automatically via method swizzling.

## Step 4: Testing

1.  Build and run the app on a **real iOS device** (Push Notifications do not work on the Simulator).
2.  Allow the permission request for notifications when the app launches.
3.  Send a test message from the Firebase Console (Messaging > New Campaign > Notifications) to the specific device token or the user segment.

## Troubleshooting

- **Did not receive notification?**
    - Check the Debug Console in Xcode for any error messages.
    - Ensure the App ID in `ios/Runner.xcodeproj` matches the one in Apple Developer Portal.
    - Ensure your device has internet connectivity.
    - Check if the app is in the foreground (notifications might not show a banner unless handled, but logs should appear).
