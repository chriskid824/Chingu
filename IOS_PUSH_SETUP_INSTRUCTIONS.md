# iOS Push Notification Setup Instructions

1.  **APNs Certificate**:
    -   Go to the Apple Developer Portal and generate an APNs certificate (or Key).
    -   Download the certificate/key.
    -   Go to the [Firebase Console](https://console.firebase.google.com/).
    -   Navigate to Project Settings -> Cloud Messaging.
    -   Under the "Apple app configuration" section, upload your APNs certificate or APNs Authentication Key.

2.  **Xcode Verification** (Optional but recommended):
    -   Open `ios/Runner.xcworkspace` in Xcode.
    -   Select the `Runner` target.
    -   Go to the "Signing & Capabilities" tab.
    -   Verify that "Push Notifications" capability is listed.
    -   Verify that "Background Modes" capability is listed with "Remote notifications" checked.
