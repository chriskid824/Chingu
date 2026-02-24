# Chingu 自動化測試清單

> 最後更新：2026-02-08 | 測試狀態：**✅ 127 通過** / **0 失敗**

---

## 📊 測試覆蓋總覽

| 類別 | 測試檔案數 | 測試數量 | 狀態 |
|------|-----------|---------|------|
| Services | 8 | 56 | ✅ All Pass |
| Providers | 2 | 12 | ✅ All Pass |
| Widgets | 3 | 27 | ✅ All Pass |
| Screens | 1 | 17 | ✅ All Pass |
| Utils | 1 | 9 | ✅ All Pass |
| App | 1 | 6 | ✅ All Pass |
| **總計** | **16** | **127** | ✅ |

---

## 📁 測試檔案清單

### Services (8 檔案)
| 檔案 | 測試項目 |
|------|----------|
| `auth_service_test.dart` | 錯誤代碼映射、Email/密碼驗證、認證狀態 |
| `report_block_service_test.dart` | 封鎖/解封、舉報、雙向封鎖檢查 |
| `chat_service_test.dart` | 聊天室建立、訊息發送、已讀狀態 |
| `dinner_event_service_test.dart` | 活動 CRUD、6人限制、狀態管理 |
| `matching_service_test.dart` | 配對邏輯、Swipe 記錄、分數計算 |
| `two_factor_auth_service_test.dart` | 驗證碼、2FA 開關、電話驗證 |
| `notification_ab_service_test.dart` | A/B 測試群組分配 |
| `badge_count_service_test.dart` | 徽章計數邏輯 |

### Providers (2 檔案)
| 檔案 | 測試項目 |
|------|----------|
| `auth_provider_test.dart` | AuthStatus、狀態管理、Profile 完成度 |
| `dinner_event_provider_test.dart` | 活動狀態管理 |

### Widgets (3 檔案)
| 檔案 | 測試項目 |
|------|----------|
| `avatar_badge_test.dart` | 頭像徽章顯示 |
| `custom_bottom_sheet_test.dart` | 底部彈窗行為 |
| `empty_state_test.dart` | 空狀態顯示 |

### Screens (1 檔案)
| 檔案 | 測試項目 |
|------|----------|
| `main_screens_test.dart` | 登入、註冊、設定、聊天、活動頁 Widget |

### Utils (1 檔案)
| 檔案 | 測試項目 |
|------|----------|
| `ab_test_manager_test.dart` | A/B 測試管理器 |

### App (1 檔案)
| 檔案 | 測試項目 |
|------|----------|
| `widget_test.dart` | App 結構、主題、導航 |

---

## 🚀 執行命令

```bash
# 執行全部測試
flutter test

# 詳細輸出
flutter test --reporter expanded

# 執行特定測試
flutter test test/services/

# 覆蓋率報告
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## 📁 測試目錄結構

```
test/
├── providers/
│   ├── auth_provider_test.dart         ✅
│   └── dinner_event_provider_test.dart ✅
├── services/
│   ├── auth_service_test.dart          ✅
│   ├── report_block_service_test.dart  ✅
│   ├── chat_service_test.dart          ✅
│   ├── dinner_event_service_test.dart  ✅
│   ├── matching_service_test.dart      ✅
│   ├── two_factor_auth_service_test.dart ✅
│   ├── notification_ab_service_test.dart ✅
│   └── badge_count_service_test.dart   ✅
├── screens/
│   └── main_screens_test.dart          ✅
├── widgets/
│   ├── avatar_badge_test.dart          ✅
│   ├── custom_bottom_sheet_test.dart   ✅
│   └── empty_state_test.dart           ✅
├── utils/
│   └── ab_test_manager_test.dart       ✅
└── widget_test.dart                    ✅
```
