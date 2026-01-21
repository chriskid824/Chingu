# iOS Push Notifications Setup

This project has been configured for iOS Push Notifications in the codebase. However, complete functionality requires manual steps in the Apple Developer Portal and Firebase Console.

## Manual Steps Required

1.  **Apple Developer Portal**
    *   Go to [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources).
    *   Select your App ID (`com.chingu.chingu`).
    *   Enable **Push Notifications** capability.
    *   Create an **APNs Key** (recommended) or APNs Certificate.
        *   **Key (p8):** Go to Keys -> Create New Key -> Enable Apple Push Notifications service (APNs). Download the `.p8` file.
        *   **Certificate (p12):** Create a certificate for Push Notifications (Sandbox & Production) and export it as `.p12`.

2.  **Firebase Console**
    *   Go to Project Settings -> Cloud Messaging.
    *   Under **Apple app configuration**:
        *   Upload your **APNs Authentication Key (.p8)** (Recommended). You will need the Key ID and Team ID.
        *   OR upload your **APNs Certificate (.p12)**.

3.  **Xcode (Optional Verification)**
    *   Open `ios/Runner.xcworkspace`.
    *   Go to Project -> Signing & Capabilities.
    *   Verify that "Push Notifications" capability is present.
    *   Verify that "Background Modes" capability is present with "Remote notifications" checked.

## Code Changes Applied

*   **`ios/Runner/Runner.entitlements`**: Created with `aps-environment` set to `development`.
*   **`ios/Runner/Info.plist`**: Added `remote-notification` to `UIBackgroundModes`.
*   **`ios/Runner.xcodeproj/project.pbxproj`**: Linked `Runner.entitlements` to the build configuration.
