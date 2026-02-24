---
description: Flutter 自動化測試指南 - 單元測試、Widget 測試、Mock 設定
---

# Flutter Testing Skill

## 測試類型

### 1. 單元測試 (Unit Tests)
測試單一函數或類別的邏輯，不涉及 UI。

```dart
// test/services/example_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/services/example_service.dart';

void main() {
  group('ExampleService', () {
    late ExampleService service;

    setUp(() {
      service = ExampleService();
    });

    test('should return expected result', () {
      final result = service.doSomething();
      expect(result, equals(expectedValue));
    });
  });
}
```

### 2. Widget 測試
測試單一 Widget 的 UI 行為。

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/widgets/my_widget.dart';

void main() {
  testWidgets('should display text', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: MyWidget()),
    );
    
    expect(find.text('Hello'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}
```

### 3. Mock Firebase 服務

```dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
  });

  test('should use mock services', () async {
    // 使用 fakeFirestore 和 mockAuth 進行測試
  });
}
```

---

## 執行命令

```bash
# 執行全部測試
flutter test

# 執行特定檔案
flutter test test/services/auth_service_test.dart

# 詳細輸出
flutter test --reporter expanded

# 覆蓋率報告
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## 測試檔案結構

```
test/
├── providers/        # Provider 測試
├── services/         # Service 測試
├── widgets/          # Widget 測試
├── utils/            # 工具類測試
└── mocks/            # Mock 類別
    ├── mock_auth_service.dart
    └── mock_firestore_service.dart
```

---

## 常用 Matchers

| Matcher | 用途 |
|---------|------|
| `expect(a, equals(b))` | 值相等 |
| `expect(a, isNull)` | 為 null |
| `expect(a, isNotNull)` | 不為 null |
| `expect(a, isTrue)` | 為 true |
| `expect(list, contains(item))` | 列表包含 |
| `expect(() => func(), throwsException)` | 拋出異常 |
| `find.text('Hello')` | 找文字 |
| `find.byType(Widget)` | 找 Widget 類型 |
| `find.byKey(Key('id'))` | 找 Key |

---

## 測試覆蓋目標

| 優先級 | 模組 | 目標覆蓋率 |
|--------|------|-----------|
| 🔴 High | Services | 80%+ |
| 🔴 High | Providers | 80%+ |
| 🟡 Medium | Widgets | 60%+ |
| 🟢 Low | Utils | 50%+ |
