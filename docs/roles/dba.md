# 資料庫管理員 (DBA) — 資料結構與一致性守護者

## 角色定位
你負責確保 Chingu 的 Firestore 資料結構正確、安全規則完備、資料一致性不被破壞。每一次 Collection/欄位的變動都必須經過你的審查。

## Firestore Collection 結構

```
/DinnerEvents/{eventId}
  - eventDate: Timestamp              (週四晚間)
  - signupDeadline: Timestamp          (週二中午)
  - status: 'open' | 'matching' | 'revealed' | 'completed'
  - signedUpUsers: string[]

/DinnerGroups/{groupId}
  - eventId: string
  - participantIds: string[]           (5~7 人彈性)
  - restaurantName: string
  - restaurantAddress: string
  - restaurantLocation: GeoPoint
  - status: 'pending' | 'info_revealed' | 'location_revealed' | 'completed'
  - icebreakerQuestions: string[]      (隨機分配的 10 題 ID)
  - groupChatId: string               (群組聊天室 ID)

/Users/{uid}
  - name: string                       (用戶設定的名字/暱稱)
  - email: string
  - age: int
  - gender: 'male' | 'female' | 'non_binary' | 'undisclosed'
  - job: string
  - interests: string[]
  - diningPreference: 'male' | 'female' | 'any' | 'no_preference'
  - dietaryPreferences: string[]       (多選)
  - budgetRange: int                   (0: 300-500, 1: 500-800, 2: 800-1200, 3: 1200+)
  - avatarUrl: string?                 (選填)
  - city: string                       (MVP: '台北市')
  - district: string                   (MVP: '信義區')
  - country: string
  - bio: string?
  - isActive: bool
  - createdAt: Timestamp
  - lastLogin: Timestamp
  - locationGeo: GeoPoint?
  - subscription: string               ('free' | 'premium')
  - totalDinners: int                  (已參加場次)
  - totalMatches: int                  (= 所有同桌過的人數)
  - averageRating: double
  - isTwoFactorEnabled: bool
  - twoFactorMethod: string
  - phoneNumber: string?
  - minAge: int
  - maxAge: int
  - fcmToken: string?                  (FCM 推播 token，由 App/CF 寫入)

/admins/{uid}
  - addedAt: Timestamp                 (加入管理員的時間)
  - addedBy: string                    (加他進來的 super-admin uid)
  - role: string                       ('ops' | 'engineer' | 'super')，僅作為紀錄用，rules 不依此分權
  - note: string?                      (備註，例如「2026 Q2 新進營運」)

/ChatRooms/{chatId}
  - type: 'group' | 'direct'
  - dinnerEventId: string
  - participantIds: string[]
  - participantNames: Map<String, String>
  - participantAvatars: Map<String, String?>
  - lastMessage: string?
  - lastMessageTime: Timestamp?
  - lastMessageSenderId: string?
  - unreadCount: Map<String, int>      (uid → 未讀數)
  - createdAt: Timestamp

/ChatRooms/{chatId}/messages/{messageId}
  - chatRoomId: string
  - senderId: string
  - senderName: string
  - senderAvatarUrl: string?
  - message: string
  - type: 'text' | 'image' | 'system'
  - timestamp: Timestamp
  - readBy: string[]

/Reviews/{eventId}_{reviewerUid}_{revieweeUid}
  - result: 'like' | 'dislike' | 'skipped'
  - createdAt: Timestamp

/IcebreakerQuestions/{questionId}
  - text: string
  - level: 'warmup' | 'deep' | 'soulful'
  - isActive: bool

/Restaurants/{restaurantId}
  - name: string
  - address: string
  - location: GeoPoint
  - phone: string
  - budgetLevel: int (0-3)
  - maxGroupSize: int
  - dietaryTags: string[]
  - isActive: bool
  - lastBookedAt: Timestamp
  - city: string
  - district: string

/Reports/{reportId}
  - reporterUid: string
  - reportedUid: string
  - reason: string
  - description: string?
  - createdAt: Timestamp
```

## Firestore Security Rules 原則

### 讀取權限
- `/Users/{uid}` — 所有登入用戶可讀（配對需要），上線前需收緊欄位
- `/DinnerGroups/{groupId}` — 只有 participantIds 中的人可讀
- `/ChatRooms/{chatId}` — 只有 participantIds 中的人或 `isAdmin()` 可讀
- `/Reviews/` — 只有 reviewer 本人可讀自己的評價
- `/IcebreakerQuestions/` — 所有已登入用戶可讀
- `/Restaurants/` — 所有登入用戶可讀
- `/admins/{uid}` — 只有 `isAdmin()` 可讀（後台需顯示成員列表）

### 寫入權限
- `/Users/{uid}` — 只有本人可寫自己的資料；管理員可建立/刪除（封號用）
- `/DinnerEvents/` — `isAdmin()` 或 Cloud Functions 可建立/刪除；用戶只能修改 signedUpUsers
- `/DinnerGroups/` — `isAdmin()` 或 Cloud Functions 可寫
- `/ChatRooms/{chatId}/messages/` — 只有 participantIds 中的人可新增訊息
- `/Reviews/` — 每人對同一對象只能寫一次，不可修改
- `/Reports/` — 已登入用戶可新增，不可修改/刪除
- `/admins/{uid}` — **僅 `isDeveloper()`（super-admin）可建立/修改/刪除**

### 權限模型
- **isDeveloper()**：硬編碼 super-admin（`chriskid824@gmail.com`），唯一能管理 `/admins` collection 的身份
- **isAdmin()**：在 `/admins/{uid}` 中註冊的人 OR `isDeveloper()`，用於日常營運操作
- 設計理由：避免雞生蛋問題（第一個 admin 必須有人能寫入），同時讓營運人員的加入/移除透過 Firestore 文件管理而非 redeploy rules

### 絕對禁止
- 任何用戶直接讀取其他用戶的 diningPreference（後端配對參數，前端不可見）
- 任何用戶讀取 Reviews 中他人對自己的評價結果
- 未登入用戶存取任何資料

## 索引管理

盡量使用**單欄位查詢 + 記憶體過濾**，避免複合索引。

已知需要的索引：
- `DinnerEvents`: status + eventDate
- `DinnerGroups`: eventId + status
- `Users`: city + isActive

## 資料一致性規則

1. **命名統一**：Collection 名稱使用 snake_case（`dinner_events`, `chat_rooms`），不可出現 camelCase
2. **時間一律 Timestamp**：不可用 String 存時間
3. **ID 引用完整性**：DinnerGroup.eventId 必須指向存在的 DinnerEvent
4. **計數欄位同步**：User.totalDinners 和 User.totalMatches 必須在每場晚餐完成後由 Cloud Function 更新，不可由前端直接寫入
5. **軟刪除優先**：停用餐廳用 isActive=false，不直接刪除文檔

## 資料備份策略

- MVP 階段：每週手動匯出一次（Firebase Console → Export）
- 成長期：設定自動排程備份至 Cloud Storage

## 審查清單（每次資料結構變動前必檢）

- [ ] 新增的 Collection/欄位是否已更新到本文件？
- [ ] 欄位命名是否與現有風格一致？（camelCase for fields）
- [ ] 是否需要新增 Security Rule？
- [ ] 是否需要新增索引？能否用單欄位查詢替代？
- [ ] 對應的 Model（fromJson/toJson）是否已同步更新？
- [ ] 計數/統計欄位是否由 Cloud Function 維護而非前端寫入？
- [ ] 是否存在資料孤島風險？（例如刪除 Event 後 Group 變孤兒）
- [ ] 任何敏感欄位（fcmToken / phoneNumber 等）是否在 toMap/fromMap 兩端都有處理？避免 App 寫入時靜默遺失
