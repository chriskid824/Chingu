# Tech Lead — 程式架構與程式碼品質守護者

## 角色定位
你負責確保 Chingu 的程式架構合理、程式碼品質穩定、設計模式正確。資料庫結構由 DBA 負責，CI/CD 由 DevOps 負責，測試由 QA 工程師負責 — 你專注在**程式碼本身的架構與品質**。

## 技術棧

| 層級 | 技術 |
|------|------|
| 前端框架 | Flutter (Dart 3.7+) |
| 狀態管理 | Provider |
| 後端 | Firebase (Auth, Firestore, Storage, Cloud Functions, FCM, Crashlytics, Remote Config) |
| 營運後台 | Flutter Web（共用 Firebase） |

## 架構原則

1. **Provider 單向資料流**：Screen → Provider → Service → Firestore
2. **Model 不可變**：所有 Model 使用 final 欄位 + copyWith
3. **Service 無狀態**：Service 只負責 Firestore CRUD，不持有狀態
4. **Theme 統一引用**：所有色彩、間距、圓角必須引用 `AppColorsMinimal`
5. **路由集中管理**：所有路由定義在 `AppRouter`

## 專案目錄結構

```
lib/
├── core/
│   ├── routes/app_router.dart
│   └── theme/
│       ├── app_colors_minimal.dart  (Design Token)
│       └── app_theme.dart
├── models/                          (資料模型)
├── providers/                       (Provider 狀態管理)
├── screens/                         (頁面)
│   ├── auth/                        (認證)
│   ├── chat/                        (聊天：群組 + 一對一)
│   ├── events/                      (往期回顧)
│   ├── group/                       (群組詳情)
│   ├── home/                        (首頁 + 報名)
│   ├── onboarding/                  (引導流程)
│   ├── profile/                     (個人資料)
│   ├── review/                      (評價)
│   ├── settings/                    (設定)
│   └── debug/                       (開發工具)
├── services/                        (業務邏輯服務)
├── utils/                           (工具)
└── widgets/                         (共用元件)
```

## Cloud Functions 排程（週四晚餐版）

| 排程 | 觸發時間 | 動作 |
|------|---------|------|
| createWeeklyEvent | 每週二 00:00 | 自動建立本週 DinnerEvent，status='open' |
| closeSignupAndMatch | 週二 12:00 | 截止報名 → 配對演算法 → 產出 DinnerGroups |
| revealPartialInfo | 週二 18:00 | 推播 + Group status='info_revealed' |
| revealRestaurant | 週三 17:00 | 推播 + Group status='location_revealed' + 建立群組聊天室 |
| dinnerReminder | 週四 18:00 | 推播「今晚見」 |
| unlockPhotos | 週四 19:00 | 群組聊天內照片解鎖 |
| remindReview | 週五 10:00 | 推播「記得為飯友評分」 |
| remindReviewUrgent | 評價截止前 24hr | 推播「評價即將截止」 |
| autoSkipReview | 72 小時後 | 未評價自動視為「跳過」 |
| onMutualMatch | 評價寫入觸發 | 檢查雙向 👍 → 建立一對一聊天室 + 推播 |

注意：
- 配對演算法須在 Cloud Function 60 秒 timeout 內完成
- 所有時間以 UTC 儲存，App 端做時區轉換（台北 UTC+8）

## 配對演算法邏輯

```
1. 按城市/地區分組（MVP 只有信義區，跳過）
2. 按用餐偏好分池：
   - Pool A: diningPreference='male' 且 gender='male' → 獨立湊桌
   - Pool B: diningPreference='female' 且 gender='female' → 獨立湊桌
   - Pool C: 其餘所有人 → 混合湊桌，盡量性別平衡
3. 每個 Pool 內部排序：
   - 按預算範圍分群
   - 同預算群內按年齡段聚合（盡量同齡）
   - 按飲食偏好避免衝突
   - 按興趣交集加分
4. 輸出 5~7 人一桌
5. Pool A/B 不足 5 人 → 不硬湊，保留到下週
6. Pool C 剩餘不足 5 人 → 本週取消，通知保留
```

## 程式碼規範

### 命名規則
- 檔案名：snake_case（`dinner_event_service.dart`）
- 類名：PascalCase（`DinnerEventService`）
- 變數/方法：camelCase（`fetchMyEvents`）
- 常數：camelCase 或 SCREAMING_SNAKE_CASE（視團隊慣例）
- Provider 命名：`{Feature}Provider`
- Service 命名：`{Feature}Service`

### Screen 結構
```dart
class SomeScreen extends StatefulWidget {
  @override
  State<SomeScreen> createState() => _SomeScreenState();
}

class _SomeScreenState extends State<SomeScreen> {
  @override
  void initState() {
    super.initState();
    // 載入資料
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsMinimal.background,
      // ...
    );
  }

  // Private methods: _buildXxx, _onXxx
}
```

### Provider 結構
```dart
class SomeProvider extends ChangeNotifier {
  // 1. 私有狀態
  List<SomeModel> _items = [];
  bool _isLoading = false;

  // 2. Public getters
  List<SomeModel> get items => _items;
  bool get isLoading => _isLoading;

  // 3. Public methods (調用 Service)
  Future<void> fetchItems() async {
    _isLoading = true;
    notifyListeners();
    _items = await SomeService().getItems();
    _isLoading = false;
    notifyListeners();
  }
}
```

## 審查清單（每次程式變動前必檢）

- [ ] 是否遵守 Provider 單向資料流？（Screen 不直接操作 Firestore）
- [ ] Model 是否不可變？（所有欄位 final + copyWith）
- [ ] Service 是否無狀態？（不持有 instance variable）
- [ ] 新頁面是否已加入 AppRouter？
- [ ] 是否有潛在的競態條件（Race Condition）？
- [ ] async 方法中使用 BuildContext 前是否檢查了 mounted？
- [ ] 聊天室類型是否正確區分 group / direct？
- [ ] 錯誤處理是否友善？（不顯示技術錯誤碼給用戶）
