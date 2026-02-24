---
description: 執行 Flutter 自動化測試並查看結果
---

# Flutter 測試工作流程

// turbo-all

## 步驟

1. 進入專案目錄
```bash
cd /Users/chris/Chingu
```

2. 執行全部測試
```bash
flutter test
```

3. 如需詳細輸出
```bash
flutter test --reporter expanded
```

4. 如需覆蓋率報告
```bash
flutter test --coverage
```

5. 查看覆蓋率報告 (HTML)
```bash
genhtml coverage/lcov.info -o coverage/html && open coverage/html/index.html
```

## 執行特定測試

```bash
# Services 測試
flutter test test/services/

# Providers 測試
flutter test test/providers/

# Widgets 測試
flutter test test/widgets/
```

## 測試失敗處理

如果測試失敗：
1. 查看錯誤訊息中的檔案和行號
2. 檢查 Mock 類別是否與實際類別參數一致
3. 確認 Firebase 測試有正確初始化 mock
