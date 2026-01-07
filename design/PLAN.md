# Chingu 專案重構計劃 - 介面優先開發

## 開發策略

採用「介面優先」的開發方式，先完成所有靜態介面設計，使用模擬數據測試 UI，最後再實現後端邏輯。

## 核心設計理念

### 🍽️ 6人晚餐聚會模式
- **固定人數**：每次晚餐固定 6 人參加（不可調整）
- **不選餐廳**：用戶只選擇預算範圍，不選擇特定餐廳
- **地點偏好**：用戶輸入偏好地區（如：信義區、大安區）
- **系統配對**：根據預算、地點、興趣等自動配對 6 人

## 完整介面清單（共 35 個）

### 📱 認證流程 (5個介面)
1. 啟動頁面 - Logo動畫、載入指示器
2. 登入頁面 - Email/密碼輸入、Google登入
3. 註冊頁面 - 註冊表單
4. 忘記密碼頁面 - 重置密碼
5. 性格測試頁面 - 15-20題問卷、進度指示器

### 📱 個人資料模組 (4個介面)
6. 新手引導頁面 - 4步驟表單（基本資料、職業、興趣、偏好）
   - 步驟 2/4（興趣選擇）新增「自我介紹（選填）」多行文字欄位（最大 200 字）
7. 個人資料頁面 - 顯示完整資料、統計資訊
8. 編輯個人資料頁面 - 編輯所有欄位
9. 個人簡介頁面 - 自我介紹編輯

### 📱 首頁與導航 (4個介面)
10. 主頁面 - 底部導航欄架構
11. 首頁動態頁面 - 推薦配對、活動卡片
12. 通知頁面 - 通知列表、已讀管理
13. 探索頁面 - 搜尋、篩選用戶

### 📱 配對模組 (5個介面)
14. 瀏覽用戶頁面 - Tinder風格滑動卡片
15. 用戶詳情頁面 - 完整個人資料顯示
16. 配對請求頁面 - 待處理/已發送請求列表
17. 配對成功頁面 - 慶祝動畫、開啟聊天
18. 群組配對頁面 - 4-6人配對結果

### 📱 預約/活動模組 (5個介面)
19. 活動列表頁面 - 即將到來的晚餐、歷史記錄
20. 創建活動頁面 - 日期時間、預算範圍選擇、地點偏好（**固定6人，不選餐廳**）
21. 活動詳情頁面 - 時間地點、預算範圍、參與者（6人）
22. 活動確認頁面 - 預約成功提示
23. 活動評價頁面 - 評分、反饋輸入
~~24. 餐廳選擇器頁面（已刪除）~~

### 📱 聊天模組 (3個介面)
25. 聊天列表頁面 - 聊天室列表、未讀標記
26. 聊天室頁面 - 訊息氣泡、輸入框、表情符號
27. 群組資訊頁面 - 成員列表、通知設定

### 📱 設定模組 (6個介面)
28. 設定主頁面 - 各項設定入口
29. 通知設定頁面 - 各類通知開關
30. 隱私設定頁面 - 可見度、封鎖列表
31. 帳號管理頁面 - 更改密碼、刪除帳號
32. 訂閱管理頁面 - 方案對比、升級
33. 關於頁面 - 版本、條款、客服

### 📱 其他功能介面 (3個介面)
34. 緊急支援頁面 - 緊急聯絡、位置分享
35. 載入頁面 - 統一載入動畫
36. 錯誤頁面 - 錯誤訊息、重試

---

## 核心功能設計（參考 Timeleft）

### 配對系統

**性格測試系統**
- 用戶首次使用時完成性格測試問卷
- 包含興趣、價值觀、社交偏好、溝通風格等維度
- 生成用戶性格檔案和標籤
- 用於智能配對演算法

**智能配對演算法**
- 基於性格測試結果計算匹配分數
- 考慮因素：
  - 性格相容度（40%）
  - 興趣重疊度（25%）
  - 年齡範圍偏好（15%）
  - 預算範圍接近度（10%）
  - 地理位置距離（10%）
- **每次晚餐固定配對 6 人**（不可調整）

### 固定時間活動模式

**每週固定晚餐日**
- 設定每週三晚上為固定晚餐日（可自訂）
- 用戶提前註冊參加當週活動
- 系統在週一自動配對並通知
- 週二確認參加，週三晚餐

**靈活預約模式**
- 用戶可自行選擇日期和時間創建晚餐活動
- 用戶選擇預算範圍（NT$ 300-500 / 500-800 / 800-1200 / 1200+）
- 用戶輸入地點偏好（例如：信義區、大安區）
- 系統自動配對 6 人（固定人數）
- **不選擇特定餐廳**，只選價格範圍和地點

### 破冰遊戲系統

**內建破冰工具**
- 每次晚餐提供 3-5 個破冰問題
- 根據參與者背景客製化問題
- 問題分類：輕鬆有趣、深度探討、創意思考
- 用戶可在晚餐前預覽問題

### 配對流程

1. **報名參加**: 用戶選擇參加固定晚餐或創建自訂活動
2. **智能配對**: 系統根據性格測試和偏好自動配對
3. **配對通知**: 提前 48 小時通知配對結果
4. **確認參加**: 用戶確認是否參加（24 小時內）
5. **餐廳預訂**: 系統根據群組偏好推薦並預訂餐廳
6. **破冰準備**: 發送破冰問題和活動資訊
7. **開啟群聊**: 創建活動專屬聊天室
8. **參加晚餐**: 提供導航和實時支援
9. **活動評價**: 結束後評價體驗和參與者
10. **後續聯繫**: 可選擇與特定成員保持聯繫

---

## 數據庫架構設計

### Firestore 集合結構

**users/** - 用戶資料
```
{
  uid: string
  email: string
  name: string
  age: int
  gender: string
  preferredMatchType: string
  job: string
  country: string
  city: string
  district: string
  budgetRange: int
  interests: array<string>
  locationGeo: GeoPoint?
  profilePhoto: string?
  bio: string?
  isActive: bool
  subscription: string
  matchPreferences: {
    minAge: int
    maxAge: int
  }
  createdAt: timestamp
  lastLogin: timestamp
}
```

**matches/** - 配對記錄
```
{
  id: string
  userIds: array<string>
  status: string
  matchType: string
  matchScore: int?
  createdAt: timestamp
  expiresAt: timestamp
}
```

**dinner_events/** - 晚餐活動
```
{
  id: string
  matchId: string
  dateTime: timestamp
  participantIds: array<string>
  confirmedIds: array<string>
  restaurantName: string?
  restaurantAddress: string?
  locationGeo: GeoPoint?
  budgetPerPerson: int?
  status: string
  chatRoomId: string
  createdAt: timestamp
}
```

**chat_rooms/** - 聊天室
```
{
  id: string
  eventId: string?
  participantIds: array<string>
  lastMessage: string?
  lastMessageAt: timestamp?
  createdAt: timestamp
}
```

**messages/** - 訊息
```
{
  id: string
  chatRoomId: string
  senderId: string
  content: string
  type: string
  readBy: array<string>
  createdAt: timestamp
}
```

---

## 開發順序

### 階段 0: 設計系統與模板生成 (2-3天)
- ✅ Flutter 專案創建
- ✅ 設計文檔創建
- ⏳ 使用 AI 生成所有 36 個介面的基礎模板
- ⏳ 定義全局配色方案和字型系統
- ⏳ 創建可重用組件庫

### 階段 1: 核心導航與認證 (2-3天)
- 整合底部導航架構
- 調整登入/註冊/忘記密碼介面
- 完善性格測試介面邏輯

### 階段 2: 個人資料與首頁 (2-3天)
- 調整新手引導流程
- 優化個人資料顯示
- 完善首頁動態布局

### 階段 3: 配對系統介面 (3-4天)
- 實現滑動卡片互動
- 連接配對請求邏輯
- 添加配對成功動畫

### 階段 4: 活動系統介面 (3-4天)
- 連接日期選擇器
- 整合地圖顯示
- 實現破冰問題輪播

### 階段 5: 聊天與設定 (2-3天)
- 整合聊天 UI 套件
- 連接設定選項
- 實現開關和選擇器邏輯

### 階段 6: 數據整合 (3-4天)
- 創建模擬數據模型
- 測試所有介面與數據連接
- 優化 UI 細節

### 階段 7: 後端整合 (5-7天)
- Firebase Auth 整合
- Firestore 數據庫設置
- 實現配對演算法
- 聊天即時功能

### 階段 8: 測試與優化 (3-5天)
- 全面測試所有功能
- 修復 bug
- 性能優化
- 動畫細節調整

**預計總時間**: 使用 AI 輔助可縮短至 22-33 天

---

## 推薦套件

```yaml
dependencies:
  # UI 組件
  flutter_staggered_animations: ^1.1.1
  shimmer: ^3.0.0
  flutter_card_swiper: ^6.0.0
  flutter_rating_bar: ^4.0.1
  
  # 日期與日曆
  table_calendar: ^3.0.9
  
  # 圖片處理
  cached_network_image: ^3.3.1
  image_picker: ^1.0.7
  
  # 地圖
  google_maps_flutter: ^2.5.0
  
  # 聊天 UI
  flutter_chat_ui: ^1.6.10
  
  # Firebase
  firebase_core: ^3.0.0
  firebase_auth: ^5.0.0
  cloud_firestore: ^5.0.0
  
  # 狀態管理
  provider: ^6.1.0
  
  # 圖標
  flutter_svg: ^2.0.9
  font_awesome_flutter: ^10.6.0
```

---

## 下一步行動

1. ✅ 專案結構建立
2. ✅ 設計文檔完成
3. **開始生成 UI 介面模板** ← 當前步驟
4. 創建設計系統和主題
5. 逐步實現各模組功能

---

最後更新: 2024/10/13



