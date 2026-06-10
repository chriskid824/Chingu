# Chingu 測試計畫（v2 — 2026-06-10）

> 取代舊的「只跑 flutter test」流程。本計畫把所有測試分成三層：
> **A 層＝Claude 可直接全自動執行**、**B 層＝CI 自動執行**、**C 層＝必須真人手動**。
> 執行方式見 `docs/testing.md`。

---

## 1. 三層測試分工總覽

| 層 | 執行者 | 環境 | 內容 |
|----|--------|------|------|
| **A：後端自動測試** | Claude（遠端容器）/ 開發者本機 | Node 20 + Java + Firebase Emulator | Cloud Functions 整合測試、Firestore Security Rules 測試、TS lint/build |
| **B：App 自動測試** | GitHub Actions CI | ubuntu runner（自動裝 Flutter 3.29.0）| Dart 單元/Widget 測試（mock Firebase）、flutter analyze |
| **C：手動測試** | 真人 + 實機 | Android/iOS 實機 | 真實 OAuth 登入、推播接收、動畫手感、深連結、時間軸實況 |

**自動化覆蓋率目標：邏輯層 100% 自動、UI 結構層 90% 自動、「體感與真機整合」約 10% 留給手動。**

---

## 2. 功能 × 測試覆蓋矩陣

### 2.1 Cloud Functions（A 層 — Claude 可直接跑）

| 功能 | 原始碼 | 現有測試 | 狀態 |
|------|--------|----------|------|
| 雙向 👍 建聊天室 + totalMatches | `onMutualMatch`（pushNotifications.ts）| `onMutualMatch.test.ts`（5 cases）| ✅ 通過 |
| Admin 權限規則 | `firestore.rules` | `adminPermissions.test.ts`（3 cases）| ✅ 通過 |
| 每週建立晚餐場次 | `createWeeklyEvent.ts` | ❌ 無 | 🔴 待補（P1）|
| 配對/週排程 | `weeklyScheduler.ts` | ❌ 無 | 🔴 待補（P1，核心演算法）|
| 飯友輪廓解鎖（週二 18:00）| `revealCompanions.ts` | ❌ 無 | 🔴 待補（P1）|
| 餐廳指定 | `restaurantAssignment.ts` | ❌ 無 | 🟡 待補（P2）|
| 訂位驗證 | `bookWithValidation.ts` | ❌ 無 | 🟡 待補（P2）|
| 72hr 自動跳過評價 | `scheduledNotifications.ts` `autoSkipReviews` | ❌ 無 | 🔴 待補（P1，影響 Match 正確性）|
| 廣播推播 admin 檢查 | `sendBroadcast.ts` | ❌ 無 | 🟡 待補（P2）|
| 推播文案產生 | `notification_content.ts` | ❌ 無 | 🟢 待補（P3，純函式最好測）|

### 2.2 Flutter App（B 層 — CI 自動）

| 功能 | 現有測試 | 狀態 |
|------|----------|------|
| 認證流程（Provider + Service + 登入畫面）| `auth_provider_test` / `auth_service_test` / `login_screen_test` | ✅ |
| 首頁狀態機（5 狀態）| `home_state_test` | ✅ |
| 報名 bottom sheet | `booking_bottom_sheet_test` | ✅ |
| 晚餐事件服務 | `dinner_event_service_test` | ✅ |
| 聊天詳情頁 | `chat_detail_screen_test` | ✅ |
| 檢舉/封鎖、2FA、Badge | 各自有測試 | ✅ |
| 系統核心流程 | `system/core_features_test` | ✅ |
| **雙盲評價即時結算** | ❌ `review_service.dart` 無測試 | 🔴 待補（P1，三大鐵律之一）|
| 強制更新邏輯 | ❌ `force_update_service.dart` 無測試 | 🟡 待補（P2）|
| 照片可見性規則（PhotoVisibility）| ❌ 無獨立測試 | 🟡 待補（P2，鐵律相關）|
| 推播 token 寫入（fcmToken 回歸）| ❌ 無 | 🟡 待補（P2，曾出過 silent bug）|

### 2.3 必須手動（C 層 — 真人實機檢查表）

自動化測不到或測了沒意義的部分，**每次發版前過一遍**：

| # | 項目 | 為什麼無法自動 |
|---|------|----------------|
| M1 | Google 登入（真帳號）| 真實 OAuth + SHA-1 簽章只能在實機驗證 |
| M2 | Apple 登入（真帳號）| Apple 要求真 iOS 裝置/憑證 |
| M3 | 推播實際送達 + 點擊跳轉正確頁面 | FCM 到系統通知列的「最後一哩」模擬不了 |
| M4 | 餐廳地圖卡片 → 跳轉 Google Maps 導航 | 跨 App deep link |
| M5 | 照片上傳（相機/相簿權限彈窗）| OS 權限 UI |
| M6 | 動畫手感（倒數圓環、邀請卡微光、翻轉、Haptic）| 美感與體感判斷 |
| M7 | 強制更新彈窗（Remote Config 實際下發）| 需真 Remote Config 環境 |
| M8 | 時間軸實況彩排：用 Seeder 造一場晚餐，實際等過 週二18:00→週三17:00→週四19:00 三個解鎖點 | 排程器在真實 Firebase 上的行為 |
| M9 | 文案語氣與繁中用詞（User 測試員角色）| 主觀判斷 |
| M10 | 弱網/斷網下的報名與聊天 | 真機網路條件 |

> M8 可大幅縮短：開發環境把解鎖時間改為「+5 分鐘 / +10 分鐘」做快轉彩排，正式環境只在上線前做一次全程實測。

---

## 3. 待補測試的執行排序（P1 先做）

**P1（核心鐵律與金流級正確性，本輪就做）**
1. `review_service` 雙盲即時結算（Dart，fake_cloud_firestore）
2. `weeklyScheduler` 配對演算法（jest + emulator）：性別偏好分桌、預算交集、5~7 人成團、不足 5 人保留下週
3. `autoSkipReviews` 72hr 逾期跳過（jest，時間可注入）
4. `revealCompanions` / `createWeeklyEvent`（jest + emulator）

**P2（防回歸）**
5. `bookWithValidation`、`restaurantAssignment`、`sendBroadcast` admin 檢查
6. `force_update_service`、`PhotoVisibility`、fcmToken 寫入回歸測試

**P3（低風險）**
7. `notification_content` 純函式測試、Widget golden tests

---

## 4. 標準測試流程（每次改 code）

```
改 code
  └─► A 層：cd functions && npm run test:emu     ← Claude 可直接代跑
  └─► B 層：git push → CI 自動跑 flutter analyze + flutter test
  └─► CI 全綠 → 才會建 APK 發佈到 App Distribution
發版前
  └─► C 層：跑一遍手動檢查表 M1~M10
```

## 5. 與上一輪測試的差異

| | 上一輪（修復前）| 本輪（v2）|
|---|---|---|
| Functions 測試 | 寫了但**從來沒跑過**（無 emulator、CI 沒這個 job）| 一鍵 `npm run test:emu`，CI 設為發佈前置關卡 |
| 測試範圍定義 | 無計畫，散落 13+2 個檔案 | 功能×覆蓋矩陣，缺口標 P1~P3 |
| 手動 vs 自動界線 | 未定義，全靠手動點 App | 明確 10 項手動檢查表，其餘全自動 |
| 驗收標準 | 「測試跑得動」 | A+B 層全綠 + C 層檢查表簽核 |
