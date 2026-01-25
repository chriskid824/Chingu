# iOS 推送通知設定指南 (iOS Push Notification Setup Guide)

本文件說明如何為 Chingu 專案配置 iOS 推送通知。部分步驟需要在 Apple Developer Portal 和 Firebase Console 上手動執行。

## 1. Apple Developer Portal 設定

1.  登入 [Apple Developer Portal](https://developer.apple.com/account/).
2.  進入 **Certificates, Identifiers & Profiles**.
3.  在 **Identifiers** 中，找到本專案的 App ID (`com.chriskid0824.chingu`)。如果不存在，請建立一個新的 App ID。
4.  在 App ID 設定中，勾選 **Push Notifications** capability。
5.  進入 **Keys**，建立一個新的 Key，勾選 **Apple Push Notifications service (APNs)**。
6.  下載生成的 `.p8` 檔案 (APNs Auth Key)，並記下 Key ID 和 Team ID。

## 2. Firebase Console 設定

1.  登入 [Firebase Console](https://console.firebase.google.com/).
2.  選擇您的專案 (chingu-98387)。
3.  點擊左上角齒輪圖示，選擇 **Project settings** (專案設定)。
4.  切換到 **Cloud Messaging** 分頁。
5.  在 **Apple app configuration** 區塊下，找到您的 iOS 應用程式 (`com.chriskid0824.chingu`)。
6.  點擊 **Upload** (上傳) 按鈕 (在 APNs Authentication Key 下)。
7.  上傳剛才下載的 `.p8` 檔案，並輸入 Key ID 和 Team ID。

## 3. 專案程式碼變更說明

本專案已完成以下自動化配置：

1.  **新增 `ios/Runner/Runner.entitlements`**:
    - 已啟用 `aps-environment` (預設為 `development`)。
    - 此檔案已連結至 Xcode 專案設定 (`CODE_SIGN_ENTITLEMENTS`)。

2.  **更新 `ios/Runner/Info.plist`**:
    - 已新增 `UIBackgroundModes` 權限，包含 `remote-notification`。

3.  **更新 `ios/Runner.xcodeproj/project.pbxproj`**:
    - `PRODUCT_BUNDLE_IDENTIFIER` 已更新為 `com.chriskid0824.chingu` 以匹配 Firebase 設定 (`GoogleService-Info.plist`)。
    - 已設定 `CODE_SIGN_ENTITLEMENTS` 指向新建立的 entitlements 檔案。

## 4. Xcode 注意事項

- 如果您使用 Xcode 開啟專案，`Runner.entitlements` 檔案可能不會顯示在左側檔案列表中（因為它是通過文字編輯直接添加到專案設定的）。這不影響編譯和功能。如果需要，您可以手動將該檔案拖入 Xcode 專案結構中。
- 請確保您的 Xcode 登入帳號具有該 App ID 的開發權限。
