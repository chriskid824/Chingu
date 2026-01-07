# Firebase 設置指南

## 📋 設置步驟

### 1️⃣ 創建 Firebase 專案

1. 前往 [Firebase Console](https://console.firebase.google.com/)
2. 點擊「新增專案」
3. 輸入專案名稱：**Chingu**
4. 選擇是否啟用 Google Analytics（建議啟用）
5. 等待專案創建完成

---

### 2️⃣ 啟用 Firebase 服務

#### Authentication（認證）
1. 在左側選單選擇「Authentication」
2. 點擊「開始使用」
3. 啟用以下登入方式：
   - ✅ **電子郵件/密碼**
   - ✅ **Google**

#### Firestore Database（資料庫）
1. 在左側選單選擇「Firestore Database」
2. 點擊「建立資料庫」
3. 選擇「以測試模式啟動」（開發階段）
4. 選擇資料庫位置：**asia-east1 (台灣)**

#### Storage（儲存空間）
1. 在左側選單選擇「Storage」
2. 點擊「開始使用」
3. 選擇「以測試模式啟動」

#### Cloud Messaging（推播通知）
1. 在左側選單選擇「Cloud Messaging」
2. 點擊「開始使用」

---

### 3️⃣ 添加應用程式

#### iOS 應用
1. 點擊 iOS 圖標
2. 輸入 iOS Bundle ID：`com.chingu.app`
3. 下載 `GoogleService-Info.plist`
4. 將檔案放到：`ios/Runner/GoogleService-Info.plist`

#### Android 應用
1. 點擊 Android 圖標
2. 輸入 Android Package Name：`com.chingu.app`
3. 下載 `google-services.json`
4. 將檔案放到：`android/app/google-services.json`

#### Web 應用
1. 點擊 Web 圖標（</>）
2. 輸入應用暱稱：`Chingu Web`
3. 複製 Firebase 配置代碼
4. 創建檔案：`lib/firebase_options.dart`

---

### 4️⃣ 配置 Android

#### 修改 `android/build.gradle`
```gradle
buildscript {
    dependencies {
        // 添加這一行
        classpath 'com.google.gms:google-services:4.4.2'
    }
}
```

#### 修改 `android/app/build.gradle`
在檔案最後添加：
```gradle
// 添加這一行
apply plugin: 'com.google.gms.google-services'
```

並確保 `minSdkVersion` 至少為 21：
```gradle
android {
    defaultConfig {
        minSdkVersion 21  // 確保至少是 21
    }
}
```

---

### 5️⃣ 配置 iOS

#### 修改 `ios/Runner/Info.plist`
在 `<dict>` 標籤內添加：
```xml
<!-- Google Sign In -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <!-- 從 GoogleService-Info.plist 中的 REVERSED_CLIENT_ID 複製 -->
            <string>YOUR_REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

#### 修改 `ios/Podfile`
確保平台版本至少為 13.0：
```ruby
platform :ios, '13.0'
```

---

### 6️⃣ 安裝依賴

```bash
cd /Users/chris/Chingu
flutter pub get
cd ios && pod install && cd ..
```

---

### 7️⃣ 初始化 Firebase

創建 `lib/firebase_options.dart`（從 Firebase Console 複製）：

```dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    authDomain: 'YOUR_AUTH_DOMAIN',
    storageBucket: 'YOUR_STORAGE_BUCKET',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_STORAGE_BUCKET',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_STORAGE_BUCKET',
    iosBundleId: 'com.chingu.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_STORAGE_BUCKET',
    iosBundleId: 'com.chingu.app',
  );
}
```

---

### 8️⃣ 更新 main.dart

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化 Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}
```

---

## 🗄️ Firestore 安全規則

在 Firebase Console 的 Firestore Database → 規則，設置以下規則：

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // 輔助函數
    function isSignedIn() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return request.auth.uid == userId;
    }
    
    // 用戶集合
    match /users/{userId} {
      allow read: if isSignedIn();
      allow write: if isOwner(userId);
    }
    
    // 晚餐活動集合
    match /dinner_events/{eventId} {
      allow read: if isSignedIn();
      allow create: if isSignedIn();
      allow update, delete: if isSignedIn() && 
        request.auth.uid in resource.data.participantIds;
    }
    
    // 聊天室集合
    match /chat_rooms/{roomId} {
      allow read, write: if isSignedIn() && 
        request.auth.uid in resource.data.participantIds;
      
      // 聊天訊息子集合
      match /messages/{messageId} {
        allow read, create: if isSignedIn() && 
          request.auth.uid in get(/databases/$(database)/documents/chat_rooms/$(roomId)).data.participantIds;
      }
    }
    
    // 通知集合
    match /notifications/{notificationId} {
      allow read, write: if isSignedIn() && 
        request.auth.uid == resource.data.userId;
    }
  }
}
```

---

## 📊 Firestore 索引

在 Firebase Console 的 Firestore Database → 索引，創建以下複合索引：

### users 集合
```
集合: users
欄位: city (升序), budgetRange (升序), isActive (升序)
```

### dinner_events 集合
```
集合: dinner_events
欄位: status (升序), dateTime (降序)
```

### notifications 集合
```
集合: notifications
欄位: userId (升序), isRead (升序), createdAt (降序)
```

---

## ✅ 驗證設置

運行以下命令測試 Firebase 連接：

```bash
flutter run
```

如果看到以下訊息表示成功：
```
[firebase_core] Successfully initialized Firebase
```

---

## 🔧 常見問題

### 問題 1：Android 編譯錯誤
**解決方案**：確保 `minSdkVersion` 至少為 21

### 問題 2：iOS Pod 安裝失敗
**解決方案**：
```bash
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
```

### 問題 3：Web 無法連接 Firebase
**解決方案**：檢查 `firebase_options.dart` 中的配置是否正確

---

## 📝 下一步

完成 Firebase 設置後，您可以：

1. ✅ 創建 Service 層（認證、資料庫操作）
2. ✅ 創建 Provider 層（狀態管理）
3. ✅ 實作登入註冊功能
4. ✅ 實作 6人晚餐配對系統

---

最後更新：2025/10/12























