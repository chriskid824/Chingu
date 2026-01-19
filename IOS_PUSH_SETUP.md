# iOS Push Notification Setup Guide

This guide describes how to configure Apple Push Notification service (APNs) for the Chingu app.

## Prerequisites

- Apple Developer Account
- Access to Firebase Console for the project

## 1. Generate APNs Authentication Key (Recommended)

Apple recommends using an APNs Authentication Key (p8 file) as it never expires and works for all your apps.

1.  Log in to the [Apple Developer Console](https://developer.apple.com/account).
2.  Go to **Certificates, Identifiers & Profiles**.
3.  Click **Keys** in the sidebar.
4.  Click the **+** button to create a new key.
5.  Enter a name (e.g., "Firebase Push Key").
6.  Check **Apple Push Notifications service (APNs)**.
7.  Click **Continue** and then **Register**.
8.  Download the `.p8` file. **Keep this safe!** You can only download it once.
9.  Note the **Key ID** (10-character string).
10. Note your **Team ID** (found in Membership details).

## 2. Upload to Firebase Console

1.  Go to the [Firebase Console](https://console.firebase.google.com/).
2.  Select your project.
3.  Click the gear icon next to "Project Overview" and select **Project settings**.
4.  Go to the **Cloud Messaging** tab.
5.  Under **Apple app configuration**, select your iOS app (`com.chingu.chingu`).
6.  Under **APNs Authentication Key**, click **Upload**.
7.  Upload the `.p8` file you downloaded.
8.  Enter the **Key ID** and **Team ID**.
9.  Click **Upload**.

## 3. Verify Bundle ID

Ensure your Apple Developer App ID matches the Bundle ID in the project: `com.chingu.chingu`.

1.  In Apple Developer Console, go to **Identifiers**.
2.  Find or create an App ID for `com.chingu.chingu`.
3.  Ensure **Push Notifications** capability is enabled for this App ID.

## 4. Certificates (Legacy Method)

If you prefer using certificates (.p12 files):
1.  Create a Certificate Signing Request (CSR) from Keychain Access on your Mac.
2.  In Apple Developer Console, go to **Certificates**.
3.  Create a new certificate for **Apple Push Notification service SSL (Sandbox & Production)**.
4.  Select the App ID `com.chingu.chingu`.
5.  Upload CSR and generate certificate.
6.  Download and install into Keychain Access.
7.  Export the private key as a `.p12` file.
8.  Upload the `.p12` file to Firebase Console under **APNs Certificates**.

## Troubleshooting

-   Ensure `Runner.entitlements` contains `aps-environment`.
-   Ensure `Info.plist` contains `remote-notification` in `UIBackgroundModes`.
-   If testing on simulator, note that APNs only works on real devices (mostly). Simulator support is limited or requires specific setup.
