---
name: firebase-setup
description: Chingu 專案的 Firebase 配置與 Firestore 資料結構
---

# Firebase Setup Skill

## Firebase 專案資訊

- **專案 ID**: 查看 `.firebaserc`
- **配置檔**: `firebase.json`

## Firestore 資料結構

### Users Collection
```
users/{userId}
├── email: string
├── displayName: string
├── photoURL: string?
├── city: string (台北/新北/桃園/台中/台南/高雄)
├── district: string
├── gender: string (male/female)
├── birthDate: timestamp
├── aboutMe: string
├── preferences: {
│   ├── genderPreference: string (opposite/same/both)
│   ├── minAge: number
│   ├── maxAge: number
│   └── maxBudget: number
│ }
├── createdAt: timestamp
└── lastLogin: timestamp
```

### Chat Rooms Collection
```
chatRooms/{chatRoomId}
├── participants: string[] (2 userIds)
├── lastMessage: string
├── lastMessageTime: timestamp
├── lastMessageSenderId: string
└── messages/{messageId}
    ├── senderId: string
    ├── text: string
    ├── createdAt: timestamp
    └── type: string (text/image/sticker)
```

### Dinner Events Collection
```
dinnerEvents/{eventId}
├── date: timestamp
├── city: string
├── district: string
├── restaurantName: string?
├── participants: string[] (max 6)
├── status: string (open/full/completed)
├── createdAt: timestamp
└── createdBy: string
```

### Matches Collection
```
matches/{matchId}
├── userId: string
├── likedUserId: string
├── isMatch: boolean
└── createdAt: timestamp
```

## 開發指令

### 部署 Firestore Rules
```bash
cd /Users/chris/Chingu
firebase deploy --only firestore:rules
```

### 部署 Cloud Functions
```bash
firebase deploy --only functions
```

### 本地模擬器
```bash
firebase emulators:start
```

## 安全規則注意事項

- 用戶只能讀取/寫入自己的資料
- 聊天室訊息只有參與者可以存取
- 配對資料只有當事人可以看到
