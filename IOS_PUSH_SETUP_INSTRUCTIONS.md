# iOS Push Notification Setup Instructions

This document outlines the manual steps required to fully enable iOS Push Notifications for the Chingu app, as these steps involve the Apple Developer Portal and Firebase Console.

## 1. Apple Developer Portal

1.  **Login** to the [Apple Developer Portal](https://developer.apple.com/account).
2.  **Certificates, Identifiers & Profiles** > **Identifiers**.
3.  Select the App ID for `com.chingu.chingu`.
4.  **Capabilities**: Scroll down and enable **Push Notifications**.
5.  **Save** the changes.
6.  **Keys**: Go to **Keys** > **Create a new key**.
    *   Name: "Firebase Push Notification Key" (or similar).
    *   Enable **Apple Push Notifications service (APNs)**.
    *   **Register** and **Download** the `.p8` file. **Keep this safe.**
    *   Note the **Key ID** and your **Team ID**.

## 2. Firebase Console

1.  **Login** to the [Firebase Console](https://console.firebase.google.com/).
2.  Select the **Chingu** project.
3.  Go to **Project settings** (gear icon) > **Cloud Messaging**.
4.  **Apple app configuration**:
    *   Locate the iOS app (`com.chingu.chingu`).
    *   Under **APNs Authentication Key**, click **Upload**.
    *   Upload the `.p8` file you downloaded from Apple.
    *   Enter the **Key ID** and **Team ID**.
    *   Click **Upload**.

## 3. Verify Local Configuration

The following changes have already been applied to the codebase:

*   **`ios/Runner/Runner.entitlements`**: Created with `aps-environment` set to `development`.
*   **`ios/Runner/Info.plist`**: Added `remote-notification` to `UIBackgroundModes`.
*   **`ios/Runner.xcodeproj/project.pbxproj`**: Updated to link the entitlements file.

## 4. Rebuild the App

1.  Run `flutter clean`.
2.  Run `flutter pub get`.
3.  Run `cd ios && pod install && cd ..`.
4.  Run `flutter run` on an iOS device (Push Notifications do not work on the Simulator).

## Troubleshooting

*   If you see "Entitlements missing", ensure Xcode has picked up `Runner.entitlements`. Open `ios/Runner.xcodeproj` in Xcode and verify the "Signing & Capabilities" tab.
*   Ensure the Bundle ID in Xcode matches the App ID in the Apple Developer Portal.
