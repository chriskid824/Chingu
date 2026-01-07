# Chingu 數據模型文檔

## 📊 數據結構概覽

### 核心模型

1. **UserModel** - 用戶資料
2. **DinnerEventModel** - 晚餐活動（固定6人）
3. **ChatMessageModel & ChatRoomModel** - 聊天系統
4. **NotificationModel** - 通知系統

---

## 👤 UserModel - 用戶資料模型

### 基本資料（新增 bio 自我介紹）
```dart
String uid              // 用戶唯一識別碼
String name             // 姓名
String email            // 電子郵件
int age                 // 年齡
String gender           // 性別: 'male' or 'female'
String job              // 職業
List<String> interests  // 興趣列表
String country          // 國家
String city             // 城市
String district         // 地區
String? bio             // 個人簡介（選填）
String? avatarUrl       // 頭像網址（選填）
```

> Onboarding（步驟 2/4 興趣選擇）新增「自我介紹（選填）」多行輸入（最大 200 字），對應到 UserModel.bio。

### 配對偏好
```dart
String preferredMatchType  // 配對類型: 'opposite', 'same', 'any'
int minAge                 // 最小年齡偏好
int maxAge                 // 最大年齡偏好
int budgetRange            // 預算範圍: 0-3
                          // 0: NT$ 300-500
                          // 1: NT$ 500-800
                          // 2: NT$ 800-1200
                          // 3: NT$ 1200+
```

### 系統欄位
```dart
bool isActive              // 帳號是否啟用
DateTime createdAt         // 建立時間
DateTime lastLogin         // 最後登入時間
GeoPoint? locationGeo      // 地理位置（選填）
String subscription        // 訂閱狀態: 'free' or 'premium'
```

### 統計資料
```dart
int totalDinners          // 參加晚餐總數
int totalMatches          // 配對總數
double averageRating      // 平均評分
```

### 輔助方法
```dart
String get budgetRangeText        // 獲取預算範圍文字
String get genderText             // 獲取性別文字
String get preferredMatchTypeText // 獲取配對類型文字
```

---

## 🍽️ DinnerEventModel - 晚餐活動模型

### 基本資訊
```dart
String id                 // 活動唯一識別碼
String creatorId          // 創建者 UID
DateTime dateTime         // 晚餐日期時間
int budgetRange           // 預算範圍: 0-3
String city               // 城市
String district           // 地區
String? notes             // 備註（選填）
```

### 參與者（固定6人）
```dart
List<String> participantIds              // 參與者 UID 列表（最多6人）
Map<String, String> participantStatus    // 參與者狀態
                                         // uid -> 'pending', 'confirmed', 'declined'
```

### 餐廳資訊（系統推薦）
```dart
String? restaurantName       // 餐廳名稱
String? restaurantAddress    // 餐廳地址
GeoPoint? restaurantLocation // 餐廳位置
String? restaurantPhone      // 餐廳電話
```

### 活動狀態
```dart
String status              // 活動狀態
                          // 'pending': 等待配對
                          // 'confirmed': 已確認
                          // 'completed': 已完成
                          // 'cancelled': 已取消
DateTime createdAt        // 建立時間
DateTime? confirmedAt     // 確認時間
DateTime? completedAt     // 完成時間
```

### 破冰與評價
```dart
List<String> icebreakerQuestions     // 破冰問題列表
Map<String, double>? ratings         // 評分: uid -> rating (1-5)
Map<String, String>? reviews         // 評論: uid -> review text
```

### 輔助方法
```dart
String get budgetRangeText           // 獲取預算範圍文字
String get statusText                // 獲取狀態文字
bool get isFull                      // 檢查是否已滿6人
int get confirmedCount               // 獲取已確認人數
bool isUserConfirmed(String userId)  // 檢查用戶是否已確認
double get averageRating             // 獲取平均評分
```

---

## 💬 ChatMessageModel - 聊天訊息模型

### 訊息資料
```dart
String id                  // 訊息唯一識別碼
String chatRoomId          // 聊天室 ID
String senderId            // 發送者 UID
String senderName          // 發送者姓名
String? senderAvatarUrl    // 發送者頭像
String message             // 訊息內容
String type                // 訊息類型: 'text', 'image', 'system'
DateTime timestamp         // 發送時間
List<String> readBy        // 已讀用戶 UID 列表
```

### 輔助方法
```dart
bool isReadBy(String userId)  // 檢查用戶是否已讀
```

---

## 💬 ChatRoomModel - 聊天室模型

### 聊天室資料
```dart
String id                                // 聊天室唯一識別碼
String dinnerEventId                     // 關聯的晚餐活動 ID
List<String> participantIds              // 參與者 UID 列表
Map<String, String> participantNames     // 參與者姓名: uid -> name
Map<String, String?> participantAvatars  // 參與者頭像: uid -> avatarUrl
String? lastMessage                      // 最後一則訊息
DateTime? lastMessageTime                // 最後訊息時間
String? lastMessageSenderId              // 最後訊息發送者 UID
Map<String, int> unreadCount             // 未讀數量: uid -> count
DateTime createdAt                       // 建立時間
```

### 輔助方法
```dart
int getUnreadCount(String userId)  // 獲取用戶的未讀數量
```

---

## 🔔 NotificationModel - 通知模型

### 通知資料
```dart
String id              // 通知唯一識別碼
String userId          // 接收者 UID
String type            // 通知類型
                      // 'match': 配對通知
                      // 'event': 活動通知
                      // 'message': 訊息通知
                      // 'rating': 評價通知
                      // 'system': 系統通知
String title          // 通知標題
String message        // 通知內容
String? imageUrl      // 圖片網址（選填）
String? actionType    // 動作類型（選填）
String? actionData    // 動作數據（選填）
bool isRead           // 是否已讀
DateTime createdAt    // 建立時間
```

### 輔助方法
```dart
NotificationModel markAsRead()  // 標記為已讀
String get iconName             // 獲取通知圖標名稱
```

---

## 🗄️ Firestore 集合結構

```
Firestore Database
├── users/                    # 用戶集合
│   └── {uid}/
│       └── (UserModel)
│
├── dinner_events/            # 晚餐活動集合
│   └── {eventId}/
│       └── (DinnerEventModel)
│
├── chat_rooms/               # 聊天室集合
│   └── {roomId}/
│       ├── (ChatRoomModel)
│       └── messages/         # 子集合：訊息
│           └── {messageId}/
│               └── (ChatMessageModel)
│
└── notifications/            # 通知集合
    └── {notificationId}/
        └── (NotificationModel)
```

---

## 📋 索引建議

### users 集合
```
- city (升序)
- budgetRange (升序)
- isActive (升序)
- 複合索引: city + budgetRange + isActive
```

### dinner_events 集合
```
- status (升序)
- dateTime (降序)
- participantIds (陣列)
- 複合索引: status + dateTime
```

### chat_rooms 集合
```
- participantIds (陣列)
- lastMessageTime (降序)
```

### notifications 集合
```
- userId (升序)
- isRead (升序)
- createdAt (降序)
- 複合索引: userId + isRead + createdAt
```

---

## 🔐 安全規則建議

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // 用戶只能讀寫自己的資料
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    
    // 活動參與者可以讀取活動資料
    match /dinner_events/{eventId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth.uid in resource.data.participantIds;
    }
    
    // 聊天室參與者可以讀寫訊息
    match /chat_rooms/{roomId} {
      allow read: if request.auth.uid in resource.data.participantIds;
      allow write: if request.auth.uid in resource.data.participantIds;
      
      match /messages/{messageId} {
        allow read: if request.auth.uid in get(/databases/$(database)/documents/chat_rooms/$(roomId)).data.participantIds;
        allow create: if request.auth.uid in get(/databases/$(database)/documents/chat_rooms/$(roomId)).data.participantIds;
      }
    }
    
    // 用戶只能讀取自己的通知
    match /notifications/{notificationId} {
      allow read, write: if request.auth.uid == resource.data.userId;
    }
  }
}
```

---

## 📝 使用範例

### 創建用戶
```dart
final user = UserModel(
  uid: 'user123',
  name: '張小明',
  email: 'user@example.com',
  age: 28,
  gender: 'male',
  job: '軟體工程師',
  interests: ['美食', '旅遊', '攝影'],
  country: '台灣',
  city: '台北市',
  district: '信義區',
  preferredMatchType: 'any',
  minAge: 25,
  maxAge: 35,
  budgetRange: 1,
  createdAt: DateTime.now(),
  lastLogin: DateTime.now(),
);

await FirebaseFirestore.instance
    .collection('users')
    .doc(user.uid)
    .set(user.toMap());
```

### 創建晚餐活動
```dart
final event = DinnerEventModel(
  id: 'event123',
  creatorId: 'user123',
  dateTime: DateTime(2025, 10, 15, 19, 0),
  budgetRange: 1,
  city: '台北市',
  district: '信義區',
  participantIds: ['user123'],
  participantStatus: {'user123': 'confirmed'},
  createdAt: DateTime.now(),
);

await FirebaseFirestore.instance
    .collection('dinner_events')
    .doc(event.id)
    .set(event.toMap());
```

---

最後更新：2025/10/12

