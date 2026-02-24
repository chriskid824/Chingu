---
name: flutter-patterns
description: Chingu 專案使用的 Flutter 架構模式與最佳實踐
---

# Flutter Patterns Skill

## 專案架構

```
lib/
├── core/                 # 核心模組
│   ├── theme/           # 主題系統
│   └── models/          # 資料模型
├── screens/             # 頁面
│   ├── auth/           # 認證模組
│   ├── home/           # 首頁
│   ├── matching/       # 配對
│   ├── chat/           # 聊天
│   └── settings/       # 設定
├── services/            # 服務層
├── providers/           # 狀態管理
├── widgets/             # 共用元件
└── utils/               # 工具函數
```

## 狀態管理

專案使用 **Provider** 進行狀態管理。

### Provider 範例
```dart
// 定義 Provider
class ChatProvider extends ChangeNotifier {
  List<ChatRoom> _chatRooms = [];
  
  List<ChatRoom> get chatRooms => _chatRooms;
  
  Future<void> loadChatRooms() async {
    _chatRooms = await ChatService.getChatRooms();
    notifyListeners();
  }
}

// 使用 Provider
Consumer<ChatProvider>(
  builder: (context, provider, child) {
    return ListView.builder(
      itemCount: provider.chatRooms.length,
      // ...
    );
  },
)
```

## 服務層模式

### Service 類別
```dart
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  static Future<User?> signIn(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result.user;
  }
}
```

## 路由系統

使用 `AppRouter` 類別管理路由：

```dart
// 導航
Navigator.pushNamed(context, '/chat-detail', arguments: chatRoom);

// 在 AppRouter 中定義
case '/chat-detail':
  final chatRoom = settings.arguments as ChatRoom;
  return MaterialPageRoute(
    builder: (_) => ChatDetailScreen(chatRoom: chatRoom),
    settings: settings,
  );
```

## Firestore 操作

### 讀取資料
```dart
final snapshot = await FirebaseFirestore.instance
    .collection('users')
    .where('city', isEqualTo: currentCity)
    .get();
```

### 寫入資料 (使用 merge)
```dart
// 使用 merge: true 避免覆蓋其他欄位
await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .set(data, SetOptions(merge: true));
```

## UI 元件規範

### 標準按鈕
```dart
ElevatedButton(
  onPressed: () {},
  child: Text('主要按鈕'),
)

OutlinedButton(
  onPressed: () {},
  child: Text('次要按鈕'),
)
```

### 載入狀態
```dart
isLoading
  ? const CircularProgressIndicator()
  : ElevatedButton(onPressed: onSubmit, child: Text('提交'))
```
