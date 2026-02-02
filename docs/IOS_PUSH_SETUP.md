# iOS Push Notification Configuration Guide

This guide describes how to configure Apple Push Notification service (APNs) for the Chingu app.

## Prerequisites

- Apple Developer Account (Admin or Account Holder role required for creating certificates/keys).
- Firebase Project with Owner/Editor access.
- Xcode installed (for verification).

## 1. Configure APNs in Apple Developer Portal

It is recommended to use **APNs Auth Key** (.p8 file) instead of certificates (.p12) as keys do not expire and work for both Development and Production environments.

### Option A: APNs Auth Key (Recommended)
1. Go to [Apple Developer Console > Certificates, Identifiers & Profiles > Keys](https://developer.apple.com/account/resources/authkeys/list).
2. Click **+** to create a new key.
3. Name it "Firebase Push Key" (or similar).
4. Check **Apple Push Notifications service (APNs)**.
5. Click **Continue** then **Register**.
6. **Download** the `.p8` file. **Important:** You can only download this once. Store it safely.
7. Note the **Key ID** (10-character string).
8. Note your **Team ID** (found in Membership details).

### Option B: APNs Certificates (.p12)
1. Go to [Apple Developer Console > Certificates, Identifiers & Profiles > Identifiers](https://developer.apple.com/account/resources/identifiers/list).
2. Select your App ID (`com.chingu.chingu` for Production, or the one matching your bundle ID).
3. Under **Capabilities**, enable **Push Notifications**.
4. Click **Edit** (or Configure).
5. Under **Apple Push Notification service SSL Certificates**, create certificates for:
   - **Development SSL Certificate** (Sandbox)
   - **Production SSL Certificate** (Sandbox & Production)
6. Follow instructions to upload CSR from Keychain Access and download the `.cer` files.
7. Double click `.cer` files to add to Keychain.
8. Export the certificate and private key as a `.p12` file from Keychain Access (do not include a password for easier CI/CD usage, or remember the password).

## 2. Upload Credentials to Firebase Console

1. Go to the [Firebase Console](https://console.firebase.google.com/).
2. Select your project.
3. Go to **Project Settings** (gear icon) > **Cloud Messaging** tab.
4. Under **Apple app configuration**:
   - If using **APNs Auth Key (.p8)** (Recommended):
     - Click **Upload** under **APNs Authentication Key**.
     - Upload the `.p8` file.
     - Enter the **Key ID** and **Team ID**.
   - If using **APNs Certificates (.p12)**:
     - Click **Upload** under **APNs Certificates**.
     - Upload your Development and Production `.p12` files accordingly.

## 3. Verify Xcode Configuration

The codebase has been updated to include the "Push Notifications" capability. To ensure everything is synced correctly:

1. Open `ios/Runner.xcworkspace` in Xcode.
2. Select the **Runner** project in the left navigator.
3. Select the **Runner** target.
4. Go to the **Signing & Capabilities** tab.
5. Verify that **Push Notifications** appears in the list of capabilities.
   - If it appears but has an issue (red text), try clicking "Fix Issue" (usually re-generates the provisioning profile).
   - If it is missing, click **+ Capability** and add **Push Notifications**. This will update the `.entitlements` file and project settings (which should already be done, but this ensures Xcode recognizes it).

## 4. `GoogleService-Info.plist`

Ensure you have downloaded the valid `GoogleService-Info.plist` for iOS from Firebase Console (Project Settings > General > Your iOS App > Download GoogleService-Info.plist) and placed it in `ios/Runner/GoogleService-Info.plist`.

## Troubleshooting

- **Notification not received?**
  - Check if the app is in background (foreground notifications require additional handling or `presentationOptions`).
  - Verify the device token is generated successfully (check logs for FCM Token).
  - Ensure the Bundle ID in Xcode matches the App ID in Apple Developer Portal and Firebase.
  - If using Simulator, Push Notifications are only supported on Xcode 11.4+ and require a `.apns` payload file for testing, or running on a real device.
