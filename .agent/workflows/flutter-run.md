---
description: 啟動 Flutter App 在 iOS 模擬器上運行
---

# 啟動 Flutter App

## 步驟

// turbo
1. 檢查可用的模擬器
```bash
flutter devices
```

// turbo
2. 啟動 iOS 模擬器 (iPhone 16 Pro)
```bash
open -a Simulator
```

// turbo
3. 運行 Flutter App
```bash
cd /Users/chris/Chingu && flutter run
```

## 注意事項
- 確保模擬器已啟動再執行 `flutter run`
- 如果出現 CocoaPods 問題，先執行 `cd ios && pod install && cd ..`
