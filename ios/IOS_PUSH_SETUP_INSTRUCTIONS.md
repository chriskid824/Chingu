# iOS Push Notification Setup Instructions

This document outlines the manual steps required to fully configure iOS Push Notifications for the Chingu app, completing Task 161.

## 1. Apple Developer Portal Configuration

1.  **Login**: Go to [Apple Developer Portal](https://developer.apple.com/account/).
2.  **Identifiers**:
    *   Navigate to **Certificates, Identifiers & Profiles** > **Identifiers**.
    *   Select your App ID (`com.chingu.chingu`).
    *   Under **Capabilities**, check **Push Notifications**.
    *   Click **Save** (and Confirm if prompted).

3.  **Certificates (APNs Key is recommended)**:
    *   **Option A: APNs Authentication Key (Recommended)**
        *   Go to **Keys**.
        *   Click **+** to create a new key.
        *   Name it (e.g., "Chingu Push Key").
        *   Check **Apple Push Notifications service (APNs)**.
        *   Click **Continue** > **Register**.
        *   **Download** the `.p8` file. **Keep this safe!** You can only download it once.
        *   Note the **Key ID** and your **Team ID**.
    *   **Option B: APNs Certificate**
        *   Go to **Certificates**.
        *   Create a new certificate for **Apple Push Notification service SSL (Sandbox & Production)**.
        *   Select the App ID.
        *   Upload a CSR (Certificate Signing Request) from your Mac (Keychain Access > Certificate Assistant > Request a Certificate from a Certificate Authority).
        *   Download the `.cer` file, double-click to install in Keychain, then export as `.p12`.

## 2. Firebase Console Configuration

1.  **Project Settings**:
    *   Go to the [Firebase Console](https://console.firebase.google.com/).
    *   Select the Chingu project.
    *   Click the gear icon > **Project settings**.
    *   Go to the **Cloud Messaging** tab.

2.  **Upload Credentials**:
    *   Under **Apple app configuration**, select your iOS app.
    *   **If using APNs Key (.p8) (Recommended)**:
        *   Upload the `.p8` file.
        *   Enter the **Key ID** and **Team ID**.
    *   **If using APNs Certificate (.p12)**:
        *   Upload the `.p12` file(s) for Development and/or Production.
        *   Enter the password if you set one.

## 3. Provisioning Profile

1.  **Update Profile**:
    *   If you are managing profiles manually, regenerate your Provisioning Profile in the Apple Developer Portal (since you enabled Push Notifications capability).
    *   Download and install the new profile.
    *   If using **Xcode Automatically Manage Signing**, Xcode should detect the changes and update the profile automatically when you next build/archive.

## 4. Verification

*   Build the app on a physical iOS device (Push Notifications do not work on Simulators without specific setup).
*   Ensure the app requests permission for notifications on launch (or when triggered).
*   Test sending a notification from Firebase Console > Messaging to the specific device token (printed in logs if you implement logging).

## Code Changes Applied

The following changes have been applied to the codebase automatically:
*   Created `ios/Runner/Runner.entitlements` with `aps-environment`.
*   Updated `ios/Runner/Info.plist` with `UIBackgroundModes`.
*   Updated `ios/Runner.xcodeproj/project.pbxproj` to link the entitlements file and configure signing.
