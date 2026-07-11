# 速查表:頁面 / 服務 / Cloud Functions

**「這個檔案是幹嘛的」一頁查完。行號會過時,grep 檔名才是穩定錨點。**

## Cloud Functions(functions/src/,TypeScript,共 10 檔)

| 檔案 | 職責 |
|---|---|
| `createWeeklyEvent.ts` | 每週自動建立晚餐活動 |
| `weeklyScheduler.ts` | 每週排程中樞(含週二 12:00 配對分組) |
| `revealCompanions.ts` | 週二 18:00 揭曉飯友匿名資訊 |
| `restaurantAssignment.ts` | 餐廳自動指派(飲食聯集+預算交集+地理中心) |
| `bookWithValidation.ts` | 報名驗證(Callable,client 直接呼叫) |
| `scheduledNotifications.ts` | 時間軸定時推播 + 72hr 逾期評價跳過 |
| `pushNotifications.ts` | trigger 推播(新訊息、雙向 Match) |
| `sendBroadcast.ts` | 管理員廣播(按城市/用戶/全部) |
| `notification_content.ts` | 推播文案範本 |
| `index.ts` | 匯出入口 |

## Services(lib/services/,11 檔)

| 檔案 | 職責 |
|---|---|
| `auth_service.dart` | Firebase Auth 封裝(Email/Google/Apple、重設密碼、Email 驗證) |
| `firestore_service.dart` | Firestore CRUD 通用層 |
| `dinner_event_service.dart` | 活動建立/查詢/報名(內有配對優化 TODO) |
| `review_service.dart` | 雙盲評價提交與結算 |
| `push_notification_service.dart` | FCM 初始化/token/前景通知 |
| `rich_notification_service.dart` | 富文本通知 |
| `badge_count_service.dart` | App icon 徽章計數 |
| `report_block_service.dart` | 檢舉與封鎖 |
| `crash_reporting_service.dart` | Crashlytics |
| `force_update_service.dart` | 強制更新(Remote Config) |
| `storage_service.dart` | Storage 上傳下載(頭像) |

## Providers(lib/providers/,7 檔,Provider 6.1.2 / ChangeNotifier)

auth / dinner_event / dinner_group / review / chat / onboarding / subscription(MVP 未啟用)

## Screens(lib/screens/,44 檔)

| 目錄 | 內容 |
|---|---|
| `home/` | 首頁動態儀表板 + home_state.dart 狀態機 + widgets/(倒數圓環、邀請卡、配對卡、飯友預覽卡、餐廳揭曉卡、待評價卡、報名 bottom sheet) |
| `auth/` | auth_gate、splash、login、register、email_verification、forgot_password |
| `onboarding/` | profile_setup、interests_selection、preferences、location、notification_permission |
| `chat/` | chat_list、chat_detail、icebreaker_screen |
| `events/` | events_screen(往期回顧)、event_detail |
| `group/` | group_detail(同桌資訊+群聊) |
| `review/` | review_screen(雙盲評價) |
| `profile/` | profile_detail、edit_profile、report_user |
| `settings/` | settings、edit_preferences、notification_settings、notification_preview、privacy_settings、blocked_users、help_center(搜尋 TODO)、about |
| `debug/` | debug_screen(開發者工具 + Seeder 入口) |
| `admin/`、`subscription/` | **空目錄**(後台與付費未實作) |
| `common/` | loading / error / empty state |
| `main_screen.dart` | 4 Tab 導覽(首頁/聊天/Events/我的) |

## Models(lib/models/,11 檔)

user / dinner_event / dinner_group / dinner_review / chat_message / restaurant / notification / booking_task / subscription / report + models.dart 匯出。欄位以各 model 的 fromJson/toJson 為準。

## 測試(test/,13 檔)

- services:auth、badge_count、dinner_event、report_block、two_factor_auth
- providers:auth_provider;screens:login、chat_detail、main_screens
- widgets:booking_bottom_sheet;system:core_features(模型序列化+狀態機)
- 缺口見 [開發進度與缺口](開發進度與缺口.md)

## 其他

- `demo/` — 28 個元件展示檔(Widgetbook 式)
- `design/FIREBASE_SETUP.md` — Firebase 初始化 7 步驟
- `firestore.indexes.json` — 13 個複合索引
- `.github/` — CI/CD:GitHub Actions → Firebase App Distribution
