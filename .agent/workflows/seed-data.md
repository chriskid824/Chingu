---
description: 產生 Firestore 測試資料用於開發
---

# 產生測試資料

## 步驟

1. 確保 App 已登入測試帳號 (test@gmail.com)

2. 導航至 Debug Screen
   - 進入設定頁面
   - 點擊「開發者選項」或「Debug」

3. 執行資料產生
   - 點擊「Generate Test Data」生成測試用戶
   - 點擊「Generate Matches」生成配對資料
   - 點擊「Generate Chats」生成聊天室資料

## 代碼位置
- Seeder: `lib/services/database_seeder.dart`

## 注意事項
- 會保留當前登入用戶的資料
- 測試用戶會生成在當前用戶的城市
- 如需清除資料，使用「清除所有數據」功能
