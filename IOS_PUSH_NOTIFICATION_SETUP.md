# iOS 推送通知配置指南 (iOS Push Notification Setup Guide)

由於涉及敏感憑證與 Xcode 本地操作，以下步驟需要您手動完成以啟用 iOS 推送通知功能。

## 步驟 1：Xcode 專案設定

1.  在 Mac 上使用 Xcode 開啟專案：`ios/Runner.xcworkspace`。
2.  在左側導航欄點選最頂部的 **Runner** (藍色圖示)。
3.  在右側設定區域，選擇 **TARGETS** 下的 **Runner**。
4.  點選頂部標籤頁 **Signing & Capabilities**。
5.  點選左上角的 **+ Capability** 按鈕。
6.  搜尋並選擇 **Push Notifications** (雙擊加入)。
    *   *這會自動產生 `ios/Runner/Runner.entitlements` 檔案。*
7.  確認下方已有 **Background Modes** 區塊（如果沒有，請同樣透過 + Capability 加入）。
    *   確認已勾選 **Remote notifications**。
    *   確認已勾選 **Background fetch**。
    *   *這些設定已在 `Info.plist` 中預先配置，Xcode 應會自動顯示勾選狀態。*

## 步驟 2：產生 Apple 推送通知驗證金鑰 (APNs Key)

1.  登入 [Apple Developer Portal](https://developer.apple.com/account)。
2.  前往 **Certificates, Identifiers & Profiles**。
3.  點選左側選單的 **Keys**。
4.  點選 **+** 建立新金鑰。
5.  輸入名稱 (例如: "Chingu Push Key")。
6.  勾選 **Apple Push Notifications service (APNs)**。
7.  點選 **Continue** 然後 **Register**。
8.  **下載** 金鑰檔案 (`.p8`)。
    *   **注意**：此檔案只能下載一次，請妥善保存。
9.  記錄下 **Key ID** (在金鑰詳情頁面可見)。
10. 記錄下 **Team ID** (在右上角帳號資訊中可見)。

## 步驟 3：設定 Firebase Console

1.  登入 [Firebase Console](https://console.firebase.google.com/) 並選擇您的專案。
2.  點選左上角的齒輪圖示 ⚙️ -> **Project settings (專案設定)**。
3.  切換到 **Cloud Messaging** 標籤頁。
4.  捲動到 **Apple app configuration** 區塊。
5.  在您的 iOS App ID 下，找到 **APNs Authentication Key** 並點選 **Upload**。
6.  上傳剛才下載的 `.p8` 檔案。
7.  輸入 **Key ID** 和 **Team ID**。
8.  點選 **Upload** 完成設定。

## 步驟 4：驗證

完成上述步驟後，重新編譯並運行 App (`flutter run`)，App 啟動時應會彈出通知授權請求對話框。同意後，App 即可接收推送通知。
