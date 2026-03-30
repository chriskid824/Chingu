# Chingu 自動化測試清單

> 最後更新：2026-03-30 | 需重新驗證（Pivot 後部分測試可能失效）

---

## 測試覆蓋總覽

| 類別 | 測試檔案數 | 說明 |
|------|-----------|------|
| Services | 5 | auth, badge_count, dinner_event, report_block, two_factor_auth |
| Providers | 1 | auth_provider |
| Screens | 3 | login_screen, chat_detail_screen, main_screens |
| Widgets | 1 | booking_bottom_sheet |
| System | 1 | core_features (整合測試) |
| App | 1 | widget_test |
| **總計** | **12** | |

---

## 測試檔案清單

### Services (5 檔案)
| 檔案 | 測試項目 | 備註 |
|------|----------|------|
| `auth_service_test.dart` | 錯誤代碼映射、Email/密碼驗證、認證狀態 | |
| `badge_count_service_test.dart` | 徽章計數邏輯 | |
| `dinner_event_service_test.dart` | 活動 CRUD、6 人限制、狀態管理 | |
| `report_block_service_test.dart` | 封鎖/解封、舉報、雙向封鎖檢查 | |
| `two_factor_auth_service_test.dart` | 驗證碼、2FA 開關 | 待確認是否仍需要 |

### Providers (1 檔案)
| 檔案 | 測試項目 |
|------|----------|
| `auth_provider_test.dart` | AuthStatus、狀態管理、Profile 完成度 |

### Screens (3 檔案)
| 檔案 | 測試項目 |
|------|----------|
| `login_screen_test.dart` | 登入頁面 Widget 測試 |
| `chat_detail_screen_test.dart` | 聊天詳情頁 Widget 測試 |
| `main_screens_test.dart` | 主頁面結構、導航 |

### Widgets (1 檔案)
| 檔案 | 測試項目 |
|------|----------|
| `booking_bottom_sheet_test.dart` | 報名底部彈窗行為 |

### System (1 檔案)
| 檔案 | 測試項目 |
|------|----------|
| `core_features_test.dart` | 核心功能整合測試 |

### App (1 檔案)
| 檔案 | 測試項目 |
|------|----------|
| `widget_test.dart` | App 結構、主題 |

---

## 待新增測試（依 Pivot 需求）

| 優先級 | 測試項目 | 說明 |
|--------|---------|------|
| P0 | 首頁 4 狀態切換 | 未報名/配對中/部分解鎖/完全解鎖 |
| P0 | 雙盲評價邏輯 | 👍/👎 互評、72 小時逾期跳過 |
| P0 | 聊天室權限閘門 | 僅雙向 👍 後才能看到聊天室 |
| P1 | DinnerGroup 配對演算法 | 6 人分組、飲食偏好、性別平衡 |
| P1 | 階段式解鎖邏輯 | 時間軸驅動的狀態轉換 |
| P2 | 餐廳配對邏輯 | 飲食聯集 + 預算交集 + 地理中心 |

---

## 執行命令

```bash
# 執行全部測試
flutter test

# 詳細輸出
flutter test --reporter expanded

# 執行特定模組
flutter test test/services/
flutter test test/screens/

# 覆蓋率報告
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## 測試目錄結構

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
