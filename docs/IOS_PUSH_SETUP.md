# iOS Push Notification Setup Guide

This guide details the steps required to fully configure iOS Push Notifications for the Chingu app.

## Prerequisites

- Apple Developer Account (Enrollment required).
- Firebase Project with "Chingu" app configured.
- macOS with Xcode installed.

## 1. Apple Developer Portal Configuration

1.  Log in to the [Apple Developer Portal](https://developer.apple.com/account).
2.  Navigate to **Certificates, Identifiers & Profiles**.
3.  **Identifiers**:
    - Select your App ID (`com.chriskid0824.chingu` based on `GoogleService-Info.plist`).
    - Scroll down to "Capabilities".
    - Check **Push Notifications**.
    - Click **Save** (or Edit -> Save).

4.  **Keys** (Recommended for Firebase):
    - Go to **Keys** > **All**.
    - Click the **+** button to create a new key.
    - Name it (e.g., "Firebase Push Key").
    - Check **Apple Push Notifications service (APNs)**.
    - Click **Continue** and then **Register**.
    - **Download** the `.p8` file. **Keep this safe; you can only download it once.**
    - Note the **Key ID** and your **Team ID**.

    *Alternatively, you can generate APNs SSL Certificates in the "Certificates" section, but the Key (.p8) approach is simpler and doesn't expire annually.*

## 2. Firebase Console Configuration

1.  Go to the [Firebase Console](https://console.firebase.google.com/).
2.  Open your project (`chingu-98387`).
3.  Click the gear icon next to "Project Overview" and select **Project settings**.
4.  Navigate to the **Cloud Messaging** tab.
5.  Scroll to **Apple app configuration**.
6.  Under **APNs Authentication Key**, click **Upload**.
7.  Upload the `.p8` file you downloaded in Step 1.
8.  Enter the **Key ID** and **Team ID**.
9.  Click **Upload**.

## 3. Xcode Configuration

Although the necessary files (`Runner.entitlements` and `Info.plist`) have been prepared, you must ensure Xcode links them correctly.

1.  Open `ios/Runner.xcworkspace` in Xcode.
2.  Select the **Runner** project in the Project Navigator (left sidebar).
3.  Select the **Runner** target in the main view.
4.  Go to the **Signing & Capabilities** tab.
5.  **Capability Check**:
    - Verify that **Push Notifications** appears in the list of capabilities.
    - If it is missing, click **+ Capability** (top left of the tab) and search for "Push Notifications". Add it.
    - Xcode should automatically detect the existing `Runner.entitlements` file. If not, verify the file is present in the file system and that the "Code Signing Entitlements" build setting points to `Runner/Runner.entitlements`.
6.  **Background Modes Check**:
    - Verify that **Background Modes** capability is present.
    - Verify that **Remote notifications** and **Background fetch** are checked. (These were added to `Info.plist`, so they should be checked).

## 4. Verification

1.  Build and run the app on a **physical iOS device** (Simulators cannot receive APNs notifications).
2.  Allow the permission request when the app launches.
3.  Check the Xcode console or Firebase Console to verify the FCM token is generated.
4.  Send a test message from Firebase Console > Messaging.
