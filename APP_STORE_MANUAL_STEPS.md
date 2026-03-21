# 🚀 App Store 上架手動步驟指南

> 以下是需要你手動完成的步驟，依順序執行。

---

## 步驟 1：啟用 GitHub Pages（5 分鐘）

隱私政策和服務條款頁面已推送到 GitHub，現在需要啟用 GitHub Pages 讓它們可以被訪問。

### 操作步驟

1. 打開瀏覽器，前往 **https://github.com/chriskid824/Chingu**
2. 點擊上方的 **Settings** (齒輪圖示)
3. 左側選單找到 **Pages**
4. 在 **Source** 區域：
   - Branch 選擇：**main**
   - Folder 選擇：**/docs**
5. 點擊 **Save**
6. 等待 1-2 分鐘，刷新頁面
7. 上方會出現綠色訊息，顯示你的網站已發佈

### 驗證

打開以下連結確認可以正常顯示：
- https://chriskid824.github.io/Chingu/privacy.html
- https://chriskid824.github.io/Chingu/terms.html

> ⚠️ 如果頁面顯示 404，請等待 5 分鐘後再試。GitHub Pages 首次部署最多需要 10 分鐘。

---

## 步驟 2：Apple Developer 帳號設定（30-60 分鐘）

### 2.1 確認 Apple Developer 帳號

1. 前往 https://developer.apple.com
2. 確認你已加入 **Apple Developer Program**（$99 USD/年）
3. 如果尚未加入：
   - 點擊 **Account** → 登入 Apple ID
   - 點擊 **Join the Apple Developer Program**
   - 依指示完成付款
   - ⚠️ 審核需要 1-2 個工作日

### 2.2 建立 App ID

1. 前往 https://developer.apple.com/account/resources/identifiers/list
2. 點擊 **+** 按鈕
3. 選擇 **App IDs** → **Continue**
4. 選擇 **App** → **Continue**
5. 填寫：
   - **Description**: `Chingu`
   - **Bundle ID**: 選擇 **Explicit**，輸入 `com.chingu.chingu`
6. 在 **Capabilities** 中勾選：
   - ✅ Push Notifications
7. 點擊 **Continue** → **Register**

### 2.3 建立 APNs Key

1. 前往 https://developer.apple.com/account/resources/authkeys/list
2. 點擊 **+** 按鈕
3. **Key Name**: `Chingu APNs Key`
4. 勾選 **Apple Push Notifications service (APNs)**
5. 點擊 **Continue** → **Register**
6. **下載 .p8 檔案**（⚠️ 只能下載一次！）
7. 記下 **Key ID**（頁面上會顯示）

### 2.4 設定 Firebase APNs

1. 前往 https://console.firebase.google.com
2. 選擇 **Chingu** 專案
3. 點擊齒輪 → **Project Settings** → **Cloud Messaging** 分頁
4. 在 **Apple app configuration** 區塊
5. 點擊 **Upload** (.p8 file)
6. 上傳剛才下載的 `.p8` 檔案
7. 填入 **Key ID** 和 **Team ID**
   - Team ID 在 https://developer.apple.com/account → Membership 頁面

### 2.5 建立 Distribution Certificate

1. 在 Xcode 中：**Xcode** → **Settings** (⌘+,) → **Accounts**
2. 確認你的 Apple ID 已加入
3. 選擇你的 Team → 點擊 **Manage Certificates**
4. 點擊 **+** → 選擇 **Apple Distribution**
5. Xcode 會自動建立並下載

### 2.6 建立 Provisioning Profile

1. 前往 https://developer.apple.com/account/resources/profiles/list
2. 點擊 **+** 按鈕
3. 選擇 **App Store Connect** → **Continue**
4. 選擇 App ID: `com.chingu.chingu` → **Continue**
5. 選擇剛才建立的 Distribution Certificate → **Continue**
6. Profile Name: `Chingu App Store` → **Generate**
7. 下載並雙擊安裝

---

## 步驟 3：App Store Connect 提交（30-45 分鐘）

### 3.1 建立 App 記錄

1. 前往 https://appstoreconnect.apple.com
2. 點擊 **My Apps** → **+** → **New App**
3. 填寫：
   - **Platforms**: iOS
   - **Name**: `Chingu - 6人晚餐社交`
   - **Primary Language**: 繁體中文
   - **Bundle ID**: 選擇 `com.chingu.chingu`
   - **SKU**: `chingu-ios-001`
4. 點擊 **Create**

### 3.2 填寫 App 資訊

在 **App Information** 頁面：

| 欄位 | 填入 |
|------|------|
| Subtitle | 認識新朋友，一起享用美食 |
| Category | 社交 (Social Networking) |
| Secondary Category | 美食與飲品 (Food & Drink) |
| Content Rights | 選擇「不包含第三方內容」 |
| Age Rating | 點擊 **Edit** → 填寫問卷（見 `APP_STORE_METADATA.md`） |

### 3.3 填寫版本資訊

在左側選擇 **1.0 Prepare for Submission**：

1. **Screenshots**:
   - 上傳截圖到 `6.5-inch (iPhone 15 Pro Max)` 欄位
   - 截圖檔案在 `screenshots/` 目錄（如果有的話）
   - 最少 1 張，建議 5 張

2. **Description**: 複製 `APP_STORE_METADATA.md` 中的描述文案

3. **Keywords**: 複製 `APP_STORE_METADATA.md` 中的關鍵字

4. **Support URL**: `https://chriskid824.github.io/Chingu/terms.html`

5. **Privacy Policy URL**: `https://chriskid824.github.io/Chingu/privacy.html`

### 3.4 上傳 Build

```bash
# 在 Xcode 中打開專案
open /Users/chris/Chingu/ios/Runner.xcworkspace

# 或使用 flutter build
flutter build ipa
```

在 Xcode 中：
1. 選擇 **Any iOS Device (arm64)** 作為 target
2. **Product** → **Archive**
3. Archive 完成後，Organizer 會自動打開
4. 選擇 Archive → **Distribute App**
5. 選擇 **App Store Connect** → **Upload**
6. 等待上傳完成（通常 5-10 分鐘）

上傳完成後，回到 App Store Connect：
1. 等待 Apple 處理（約 10-30 分鐘）
2. 在 **Build** 區域選擇剛上傳的 build
3. 填寫 **Export Compliance**：選擇「否」（除非你使用了自訂加密）

### 3.5 提交審核

1. 確認所有必填欄位都已填寫（頁面頂部會顯示警告）
2. 點擊 **Submit for Review**
3. 回答審核相關問題：
   - **Sign-In Required**: 是（提供測試帳號）
   - **Demo Account**: `test1@example.com` / `Test123!`
4. 點擊 **Submit**

> 📝 審核通常需要 1-3 個工作日。首次提交可能會久一些。

---

## 步驟 4：實機測試（60-90 分鐘）

### 準備工作

1. 將 iPhone 連接到 Mac
2. 在 iPhone 上信任你的開發者證書：
   - **設定** → **一般** → **VPN 與裝置管理** → 信任你的 Developer 帳號

### 安裝到實機

```bash
# 方法 1：Flutter 直接安裝
flutter run --release

# 方法 2：使用 Xcode
# 打開 Runner.xcworkspace
# 選擇你的實機作為 target
# ⌘+R 執行
```

### 測試清單

請對照 `/Users/chris/Chingu/MANUAL_TESTING_CHECKLIST.md` 逐項測試：

#### 必測項目（Apple 必定會檢查）

| # | 項目 | 重點 |
|---|------|------|
| 1 | 註冊新帳號 | 完整流程能走完 |
| 2 | 登入/登出 | 正常切換 |
| 3 | 刪除帳號 | ⚠️ Apple 特別關注此功能 |
| 4 | 隱私政策連結 | 點擊後能開啟網頁 |
| 5 | 配對功能 | 滑動流暢、配對正常 |
| 6 | 聊天功能 | 發送/接收訊息正常 |
| 7 | 推播通知 | 能收到通知 |
| 8 | 各頁面無閃退 | 切換所有 Tab |

#### 裝置相容性

| 裝置 | 確認項目 |
|------|----------|
| 你的 iPhone | 所有功能正常運作 |
| 不同網路 | WiFi 和行動網路都能正常使用 |
| 螢幕旋轉 | App 保持直向（不應轉向） |

### 常見問題排解

- **閃退**: 查看 Xcode Console 的 crash log
- **推播不通**: 確認 APNs Key 已設定、Firebase 有正確的 Team ID
- **登入失敗**: 確認 Firebase Auth 已在 Console 啟用 Email/Password

---

## ✅ 完成順序總結

```
1. 啟用 GitHub Pages          ← 5 分鐘
2. Apple Developer 帳號設定    ← 30-60 分鐘
3. 實機測試                    ← 60-90 分鐘
4. App Store Connect 提交      ← 30-45 分鐘
5. 等待審核                    ← 1-3 天
```

**總計預估：約 2-3 小時 + 1-3 天審核等待**
