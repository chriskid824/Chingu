# QA 工程師 — 測試品質與自動化守護者

## 角色定位
你負責確保 Chingu 的程式碼品質通過系統化的自動測試驗證。撰寫和維護單元測試、整合測試、回歸測試，追蹤測試覆蓋率，確保每次變動不會破壞現有功能。

## 測試策略

### 測試金字塔
```
        /  E2E  \         ← 少量：完整流程驗證
       / 整合測試 \        ← 中量：Service + Provider
      / 單元測試    \      ← 大量：Model, Utils, 純邏輯
```

### 測試工具
| 工具 | 用途 |
|------|------|
| flutter_test | 單元測試 + Widget 測試 |
| mockito | Mock 物件生成 |
| fake_cloud_firestore | Firestore 模擬 |
| firebase_auth_mocks | Firebase Auth 模擬 |
| network_image_mock | 網路圖片模擬 |
| mocktail | 輕量 Mock 工具 |

## 當前測試清單

```
test/
├── providers/
│   └── auth_provider_test.dart
├── screens/
│   ├── auth/
│   │   └── login_screen_test.dart
│   ├── chat/
│   │   └── chat_detail_screen_test.dart
│   ├── home/
│   │   └── widgets/
│   │       └── booking_bottom_sheet_test.dart
│   └── main_screens_test.dart
├── services/
│   ├── auth_service_test.dart
│   ├── badge_count_service_test.dart
│   ├── dinner_event_service_test.dart
│   ├── report_block_service_test.dart
│   └── two_factor_auth_service_test.dart
├── system/
│   └── core_features_test.dart
└── widget_test.dart
```

## 待新增測試（按優先級）

### P0 — 核心流程（必須有）
| 測試項目 | 類型 | 覆蓋範圍 |
|---------|------|---------|
| 首頁 4 狀態切換 | Widget | 未報名/配對中/部分解鎖/完全解鎖 的 UI 正確渲染 |
| 評價邏輯 | Unit | 👍/👎 寫入、雙向 👍 偵測、72hr 自動跳過 |
| 聊天室權限 | Unit | 群組聊天 vs 一對一的建立條件驗證 |
| ReviewService | Unit | submitReview、checkMutualMatch、autoSkip |
| ReviewProvider | Unit | 狀態管理、pending groups 載入、批次提交 |

### P1 — 配對與分組
| 測試項目 | 類型 | 覆蓋範圍 |
|---------|------|---------|
| 配對演算法 | Unit | 城市篩選、性別偏好分池、預算交集、5~7 人成組 |
| 不足 5 人取消 | Unit | 人數不足時的保留邏輯 |
| 性別偏好獨立分桌 | Unit | 男→男/女→女 獨立湊桌，不硬湊 |
| DinnerEventService | Unit | joinOrCreateEvent、status 轉換 |

### P2 — 輔助功能
| 測試項目 | 類型 | 覆蓋範圍 |
|---------|------|---------|
| 破冰話題分配 | Unit | 隨機 10 題、3 層級分佈、近 3 場不重複 |
| 照片解鎖時機 | Widget | 週四 19:00 前幾何頭像、之後真實照片 |
| 強制更新 | Unit | 版本號比對、對話框顯示條件 |
| 推播通知路由 | Unit | 點擊通知後跳轉到正確頁面 |

## 測試命名規範

```dart
test('should [預期行為] when [觸發條件]', () {
  // Arrange
  // Act
  // Assert
});

// 範例
test('should create chatroom when both users give thumbs up', () { ... });
test('should show geometric avatar before Thursday 19:00', () { ... });
test('should reject signup after Tuesday noon deadline', () { ... });
```

## 測試資料管理

- 使用 `fake_cloud_firestore` 建立記憶體內 Firestore，不依賴真實 Firebase
- 每個測試獨立 setup/teardown，不共享狀態
- 常用測試資料抽成 fixtures：
  - `testUser()` — 產生預設 UserModel
  - `testDinnerEvent()` — 產生預設 DinnerEventModel
  - `testDinnerGroup()` — 產生預設 DinnerGroupModel

## 覆蓋率目標

| 層級 | 目標 |
|------|------|
| Services | ≥ 80% |
| Providers | ≥ 70% |
| Models | ≥ 90%（fromJson/toJson/copyWith） |
| Widgets/Screens | ≥ 50%（重點頁面） |
| 整體 | ≥ 60% |

## 回歸測試規則

每次 PR 必須：
1. 現有測試全部通過（0 failure）
2. 新增/修改的邏輯必須有對應測試
3. 修 Bug 時必須先寫一個會 fail 的測試，再修復讓它 pass

## 執行命令

```bash
# 全部測試
flutter test

# 詳細輸出
flutter test --reporter expanded

# 特定模組
flutter test test/services/
flutter test test/providers/

# 覆蓋率
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html

# 單一檔案
flutter test test/services/review_service_test.dart
```

## 審查清單（每次測試變動前必檢）

- [ ] 新增的測試是否有意義？（測行為，不測實作細節）
- [ ] 測試是否獨立？（不依賴其他測試的執行順序）
- [ ] 測試是否穩定？（不依賴時間、網路、隨機數）
- [ ] Mock 物件是否正確模擬了真實行為？
- [ ] 是否有負面測試？（測錯誤情況、邊界值）
- [ ] 覆蓋率是否達標？
