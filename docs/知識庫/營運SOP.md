# 營運 SOP(後台未建置期的實際操作法)

**規格版 SOP 在 `docs/roles/ops_manager.md`(權威);本頁回答「後台網站還沒做,現在每一步實際怎麼操作」。**

## 每週時間軸與操作對照

| 時間 | 系統動作 | 營運人員動作 | 目前實際工具 |
|---|---|---|---|
| 週二 00:00 | 自動建立 DinnerEvent | — | 確認 Functions log(Firebase Console)有跑 |
| 週二 12:00 | 截止 + 配對演算法 | 確認配對結果合理 | **Firestore Console** 看 `dinner_groups`;不合理只能直接改 doc |
| 週二 12:30~17:00 | — | 指定餐廳、致電訂位、回填確認 | Firestore Console 手改 `dinner_groups` 的餐廳欄位;餐廳清單看 `restaurants` 集合 |
| 週二 18:00 | 推播部分解鎖 | 確認推播送達 | Functions log + 自己手機實測 |
| 週三 17:00 | 推播餐廳揭曉 + 建群聊 | 確認餐廳資訊正確 | App 內實看 |
| 週五 10:00~ | 評價提醒、72hr 跳過 | 檢查本週數據 | Firestore Console 看 `dinner_reviews` 筆數 |

手動廣播:呼叫 `sendBroadcast` Cloud Function(可按城市/用戶/全部定向)。
測試資料:debug_screen 的 Seeder(6 模組 15 個 User Case,僅開發者帳號可用)。

## 異常處理速記(詳見 ops_manager.md)

- 不足 5 人 → 系統自動取消、保留下週(理論上自動;上線初期人工核對)
- 特定偏好湊不滿 → 該池保留下週,不硬湊
- 訂位全失敗 → 擴大範圍重指定;極端該桌取消
- no-show → 累計 2 次警告、3 次停權 30 天(**目前無系統欄位支援,只能 Console 手記**)
- 檢舉 → `reports` 集合只有後台可讀 → 目前用 Firestore Console 審核

## 內容管理

- 破冰話題:`icebreaker_questions` 集合,僅開發者可寫 → Console 手動維護;分級 warmup/deep/soulful,每場 3/4/3 題
- 餐廳:`restaurants` 集合,欄位要求見 ops_manager.md(名稱/地址/電話/預算 0~3/飲食標籤/容量)

## 風險備忘

- 所有 Console 手改都**繞過 App 的資料驗證**,改 `dinner_groups` 時注意欄位拼寫(參照 lib/models/dinner_group_model.dart)
- 後台網站(Phase 6)完成前,以上人工流程是每週必做;後台功能需求清單見 ops_manager.md 第 73~112 行
