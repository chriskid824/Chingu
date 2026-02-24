---
name: tdd-workflow
description: 測試驅動開發工作流程原則 - RED-GREEN-REFACTOR 循環
---

# TDD Workflow (測試驅動開發)

> 先寫測試，後寫程式碼。

## 1. TDD 循環

```
🔴 RED → 寫失敗的測試
    ↓
🟢 GREEN → 寫最小程式碼讓測試通過
    ↓
🔵 REFACTOR → 改善程式碼品質
    ↓
   重複...
```

## 2. TDD 三定律

1. 只有讓失敗的測試通過時才寫生產程式碼
2. 只寫足夠展示失敗的測試
3. 只寫足夠讓測試通過的程式碼

## 3. RED 階段原則

### 該寫什麼

| 焦點 | 範例 |
|------|------|
| 行為 | "should add two numbers" |
| 邊界情況 | "should handle empty input" |
| 錯誤狀態 | "should throw for invalid data" |

### RED 階段規則
- 測試必須先失敗
- 測試名稱描述預期行為
- 每個測試一個斷言（理想情況）

## 4. GREEN 階段原則

### 最小程式碼

| 原則 | 意義 |
|------|------|
| **YAGNI** | You Aren't Gonna Need It |
| **最簡單的事** | 寫最少讓測試通過的程式碼 |
| **不優化** | 先讓它運作 |

### GREEN 階段規則
- 不寫不需要的程式碼
- 還不要優化
- 通過測試，僅此而已

## 5. REFACTOR 階段原則

### 要改進什麼

| 領域 | 動作 |
|------|------|
| 重複 | 提取共同程式碼 |
| 命名 | 讓意圖清晰 |
| 結構 | 改善組織 |
| 複雜度 | 簡化邏輯 |

### REFACTOR 規則
- 所有測試必須保持綠色
- 小的增量變更
- 每次重構後 commit

## 6. AAA 模式

每個測試遵循：

| 步驟 | 目的 |
|------|------|
| **Arrange** | 設置測試數據 |
| **Act** | 執行被測試的程式碼 |
| **Assert** | 驗證預期結果 |

## 7. 何時使用 TDD

| 情境 | TDD 價值 |
|------|---------|
| 新功能 | 高 |
| Bug 修復 | 高（先寫測試）|
| 複雜邏輯 | 高 |
| 探索性開發 | 低（先 spike，然後 TDD）|
| UI 佈局 | 低 |

## 8. 測試優先順序

| 優先級 | 測試類型 |
|--------|---------|
| 1 | Happy path |
| 2 | 錯誤情況 |
| 3 | 邊界情況 |
| 4 | 效能 |

## 9. 反模式

| ❌ 不要做 | ✅ 要做 |
|----------|--------|
| 跳過 RED 階段 | 先看測試失敗 |
| 之後寫測試 | 之前寫測試 |
| 過度工程初始版本 | 保持簡單 |
| 多個斷言 | 每個測試一個行為 |
| 測試實現 | 測試行為 |

## 10. Flutter 專案的 TDD

### Widget 測試範例

```dart
void main() {
  testWidgets('登入按鈕應該在表單有效時可點擊', (tester) async {
    // Arrange
    await tester.pumpWidget(MaterialApp(home: LoginScreen()));
    
    // Act
    await tester.enterText(find.byKey(Key('email')), 'test@test.com');
    await tester.enterText(find.byKey(Key('password')), 'password123');
    await tester.pump();
    
    // Assert
    final button = find.byType(ElevatedButton);
    expect(tester.widget<ElevatedButton>(button).onPressed, isNotNull);
  });
}
```

### Unit 測試範例

```dart
void main() {
  group('MatchingService', () {
    test('應該過濾掉已配對的用戶', () {
      // Arrange
      final service = MatchingService();
      final currentUser = User(id: '1', matchedWith: ['2']);
      final potentialMatches = [User(id: '2'), User(id: '3')];
      
      // Act
      final result = service.filterMatches(currentUser, potentialMatches);
      
      // Assert
      expect(result.length, 1);
      expect(result.first.id, '3');
    });
  });
}
```

> **記住:** 測試就是規格。如果你無法寫測試，你就不了解需求。
