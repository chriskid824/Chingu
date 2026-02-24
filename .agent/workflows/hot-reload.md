---
description: 對運行中的 Flutter App 執行熱重載
---

# 熱重載 (Hot Reload)

## 步驟

// turbo
1. 發送熱重載指令到運行中的 Flutter 進程
```
向 Flutter 運行終端發送 'r' 字符
```

## 使用時機
- 修改任何 Dart 代碼後
- UI 樣式調整後
- 狀態管理邏輯更新後

## 注意事項
- Hot Reload (`r`) 保留 App 狀態
- Hot Restart (`R`) 會重置 App 狀態
- 如果 Hot Reload 無效，嘗試 Hot Restart
