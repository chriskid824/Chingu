---
name: chingu-auth-rules
description: Chingu 專案認證相關的不可違反規則
---

# Chingu 認證規則

## 🚫 絕對禁止事項

### 1. 不准隱藏 Apple 登入按鈕
- Apple 登入按鈕必須在 **所有平台**（iOS 和 Android）都顯示
- 不准用 `Platform.isIOS` 或任何條件來隱藏 Apple 按鈕
- 即使 Android 上的 Apple 登入尚未完全設定，按鈕仍然要顯示

### 2. 不准移除登入按鈕
- 登入頁面必須始終包含三個登入選項：
  1. Email/密碼登入
  2. Apple 登入
  3. Google 登入

## 📋 登入架構

### Google 登入
- iOS: 使用 `clientId`（iOS Client ID）
- Android: 使用 `serverClientId`（Web Client ID）+ `google-services.json` 中的 Android Client ID
- `google-services.json` 必須包含 `client_type: 1`（Android）和 `client_type: 3`（Web）

### Apple 登入
- iOS: 使用原生 `sign_in_with_apple` 套件
- Android: 使用 Firebase `signInWithProvider(AppleAuthProvider())`（Web OAuth 流程）
- Android 的 Apple 登入需要在 Firebase Console 設定 Apple Developer 的 Service ID 和 Private Key
