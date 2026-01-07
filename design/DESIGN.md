# Chingu App - 完整設計文檔

## 專案概述

Chingu 是一個社交晚餐應用，旨在幫助用戶透過 **6人晚餐聚會** 建立有意義的社交連結。本文檔包含所有介面設計規格和 AI 生成 prompts。

### 核心特色
- 🍽️ **固定 6 人晚餐聚會**（不支援 1對1 或其他人數）
- 💰 **只選價格範圍**（不選擇特定餐廳）
- 📍 **地點偏好選擇**（用戶輸入偏好地區）
- 🎲 **系統自動配對**（根據預算、地點、興趣等條件）

## 設計系統

### 配色方案

```
主色 (Primary): #FF6B35 (溫暖橙色)
次要色 (Secondary): #004E89 (深藍色)
背景色 (Background): #F7F7F7 (淺灰白)
文字色 (Text): #2D3142 (深灰)
成功色 (Success): #06A77D (綠色)
警告色 (Warning): #F4D35E (黃色)
錯誤色 (Error): #EF476F (紅色)
```

### 字型系統

- **中文**: Noto Sans TC
- **英文**: Roboto
- **標題**: Bold, 24-32px
- **正文**: Regular, 14-16px
- **輔助文字**: Regular, 12-14px

### 間距系統

```
xs: 4px
sm: 8px
md: 16px
lg: 24px
xl: 32px
xxl: 48px
```

### 圓角設計

```
按鈕: 8px
卡片: 12px
輸入框: 8px
頭像: 圓形 (50%)
```

---

## 完整介面清單（共 35 個）

### 📱 認證流程 (5個)
1. 啟動頁面 (Splash Screen)
2. 登入頁面 (Login Screen)
3. 註冊頁面 (Register Screen)
4. 忘記密碼頁面 (Forgot Password)
5. 性格測試頁面 (Personality Test)

### 📱 個人資料 (4個)
6. 新手引導頁面 (Onboarding)
7. 個人資料頁面 (Profile)
8. 編輯個人資料 (Edit Profile)
9. 個人簡介頁面 (Bio)

#### Onboarding - 步驟 2/4 興趣選擇
- 新增「自我介紹（選填）」多行文字輸入框（最大 200 字）
- 目的：讓配對更了解使用者、提升群組互動

### 📱 首頁與導航 (4個)
10. 主頁面 (Main with Bottom Nav)
11. 首頁動態 (Home Feed)
12. 通知頁面 (Notifications)
13. 探索頁面 (Explore)

### 📱 配對模組 (5個)
14. 瀏覽用戶 (Browse Users - Tinder Style)
15. 用戶詳情 (User Detail)
16. 配對請求 (Match Requests)
17. 配對成功 (Match Success)
18. 群組配對 (Group Matching)

### 📱 活動模組 (5個)
19. 活動列表 (Events List) - 即將到來 / 歷史記錄
20. 創建活動 (Create Event) - 6人晚餐預約
21. 活動詳情 (Event Detail) - 顯示參加人數、預算、地點
22. 活動確認 (Event Confirmation) - 預約成功頁面
23. 活動評價 (Event Rating) - 晚餐後評價
~~24. 餐廳選擇器 (已刪除)~~

### 📱 聊天模組 (3個)
25. 聊天列表 (Chat List)
26. 聊天室 (Chat Room)
27. 群組資訊 (Group Info)

### 📱 設定模組 (6個)
28. 設定主頁 (Settings)
29. 通知設定 (Notification Settings)
30. 隱私設定 (Privacy Settings)
31. 帳號管理 (Account Management)
32. 訂閱管理 (Subscription)
33. 關於頁面 (About)

### 📱 其他功能 (3個)
34. 緊急支援 (Emergency Support)
35. 載入頁面 (Loading States)
36. 錯誤頁面 (Error States)

---

## 專案結構

```
lib/
├── main.dart
├── core/
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── app_colors.dart
│   │   └── app_text_styles.dart
│   ├── constants/
│   │   └── app_constants.dart
│   └── utils/
│       └── helpers.dart
├── design/
│   ├── auth/
│   │   ├── splash_screen.dart
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   ├── forgot_password_screen.dart
│   │   └── personality_test_screen.dart
│   ├── profile/
│   │   ├── onboarding_screen.dart
│   │   ├── profile_screen.dart
│   │   ├── edit_profile_screen.dart
│   │   └── bio_screen.dart
│   ├── home/
│   │   ├── main_screen.dart
│   │   ├── home_feed_screen.dart
│   │   ├── notifications_screen.dart
│   │   └── explore_screen.dart
│   ├── matching/
│   │   ├── browse_users_screen.dart
│   │   ├── user_detail_screen.dart
│   │   ├── match_requests_screen.dart
│   │   ├── match_success_screen.dart
│   │   └── group_matching_screen.dart
│   ├── events/
│   │   ├── booking_screen.dart
│   │   ├── create_event_screen.dart
│   │   ├── event_detail_screen.dart
│   │   ├── restaurant_picker_screen.dart
│   │   ├── icebreaker_screen.dart
│   │   └── event_review_screen.dart
│   ├── chat/
│   │   ├── chat_list_screen.dart
│   │   ├── chat_room_screen.dart
│   │   └── group_info_screen.dart
│   ├── settings/
│   │   ├── settings_screen.dart
│   │   ├── notification_settings_screen.dart
│   │   ├── privacy_settings_screen.dart
│   │   ├── account_management_screen.dart
│   │   ├── subscription_screen.dart
│   │   └── about_screen.dart
│   └── common/
│       ├── emergency_support_screen.dart
│       ├── loading_screen.dart
│       └── error_screen.dart
└── widgets/
    ├── buttons/
    ├── cards/
    ├── inputs/
    └── common/
```

---

## 開發階段

### 階段 0: 設計系統 (已完成)
- ✅ Flutter 專案創建
- ⏳ 設計系統定義
- ⏳ 通用組件庫

### 階段 1: 認證介面 (進行中)
- 創建所有認證相關介面的靜態模板

### 階段 2-6: 其他模組介面
- 逐步創建所有介面的靜態模板

### 階段 7: 數據整合
- 使用模擬數據測試所有介面

### 階段 8-9: 後端整合
- Firebase 整合
- 實現業務邏輯

---

## 使用說明

### 查看介面
所有設計介面都在 `lib/design/` 資料夾中，按模組分類。

### 運行專案
```bash
flutter run
```

### 查看特定介面
修改 `lib/main.dart` 中的 `home` 參數來查看不同介面。

---

## 下一步

1. 完成設計系統和主題配置
2. 創建可重用組件庫
3. 生成所有 36 個介面的靜態模板
4. 使用模擬數據測試
5. 實現導航和路由
6. 整合 Firebase
7. 實現業務邏輯

---

最後更新: 2024/10/13

