# 測試指南（Testing Guide）

> 維護角色：QA 工程師 + DevOps。本文說明 Chingu 兩套測試（Flutter / Cloud Functions）如何在本機與 CI 執行，避免再次卡在「測試跑不起來」。

---

## 一、測試總覽

| 測試類型 | 位置 | 數量 | 框架 | 依賴 |
|----------|------|------|------|------|
| Flutter 單元/Widget 測試 | `test/` | 13 檔 | `flutter_test` + `mockito` / `fake_cloud_firestore` / `firebase_auth_mocks` | 需安裝 Flutter SDK |
| Cloud Functions 整合測試 | `functions/test/` | 2 檔（7 cases）| `jest` + `ts-jest` + `@firebase/rules-unit-testing` | 需 **Firebase Emulator**（Node 20 + Java）|

---

## 二、Flutter 測試

### 前置需求
- Flutter SDK `3.29.0`（與 CI 一致，見 `.github/workflows/distribute.yml`）
- 本專案使用的容器/環境若沒有 Flutter，需先安裝；CI 的 `ubuntu-latest` runner 會自動安裝。

### 執行
```bash
flutter pub get
flutter analyze --no-fatal-infos lib/ test/
flutter test
```

Flutter 測試全部使用 mock 套件（`fake_cloud_firestore`、`firebase_auth_mocks`），**不需要連真實 Firebase，也不需要 emulator**。

---

## 三、Cloud Functions 測試（重點，過去卡關處）

### 為什麼之前跑不起來
1. `functions/` 的依賴未安裝（`npm ci` / `npm install`）。
2. 測試是**整合測試**，需要 Firestore + Functions Emulator 實際運行，光跑 `jest` 會連不上 emulator。
3. 舊的 `test:emu` 腳本只有 `npm run build && jest`，**沒有啟動 emulator**。
4. CI 完全沒有這個 job，TypeScript 測試從未在 pipeline 跑過。

以上皆已修正。

### 前置需求
- Node 20
- Java（emulator 需要，本機/CI 皆須具備；CI 用 `setup-java` zulu 17）
- 不需全域安裝 firebase-tools，腳本以 `npx firebase-tools` 呼叫。

### 執行（一鍵）
```bash
cd functions
npm ci          # 或 npm install
npm run test:emu
```

`test:emu` 會：`tsc 編譯` → `firebase emulators:exec` 啟動 Firestore + Functions Emulator → 在 emulator 內跑 `jest` → 自動關閉 emulator。

### 預期結果
```
Test Suites: 2 passed, 2 total
Tests:       7 passed, 7 total
```

> 測試 log 中若出現 `app/invalid-credential` / `metadata.google.internal ... ENOTFOUND` 的 FCM 推播錯誤是**正常的**——本機沒有真實 GCP 憑證，推播會優雅失敗，但不影響「建立聊天室 / totalMatches +1」等核心斷言。

### 測試涵蓋（`onMutualMatch.test.ts`）
1. 雙向 like → 建立 chat_room（確定性 ID）
2. 單向 like → 不建立
3. 重複寫入 → 不會建立第二份 chat_room
4. 雙方 `totalMatches` 各自 +1（batch 原子性）
5. like + dislike → 不構成 Match

### 測試涵蓋（`adminPermissions.test.ts`）
1. 一般用戶無法寫入受保護集合（restaurants / icebreaker_questions）
2. `/admins/{uid}` 註冊的用戶可寫入受保護集合
3. 一般用戶無法管理 `/admins` collection（僅 super-admin 可）

---

## 四、CI 行為

`.github/workflows/distribute.yml`（push 到 `main` / `release` 觸發）：

1. **`functions_test` job**：安裝 Node 20 + Java 17 → `npm ci` → `npm run test:emu`。
2. **`build_and_distribute` job**：`needs: functions_test`，Functions 測試通過後才跑 `flutter analyze` / `flutter test` / 建置 APK / 發佈 Firebase App Distribution。

亦即 **Functions 測試是發佈的前置關卡**，掛掉就不會出 build。
