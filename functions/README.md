# Firebase Cloud Functions - Broadcast Notifications

## Overview
This directory contains Firebase Cloud Functions for the Chingu application. The main function is `sendBroadcast`, which allows admins to send push notifications to users.

## Setup

### 1. Install Dependencies
```bash
cd functions
npm install
```

### 2. Configure Firebase
Make sure you have Firebase CLI installed and logged in:
```bash
npm install -g firebase-tools
firebase login
```

### 3. Initialize Firebase (if not already done)
```bash
firebase init functions
```

###4. Build TypeScript
```bash
npm run build
```

### 5. Deploy
```bash
npm run deploy
```

## Functions

### sendBroadcast
Sends push notifications to users based on different targeting criteria.

#### Admin Setup
Before using this function, you need to add admin users to Firestore:

```javascript
// In Firestore console, create a collection called 'admins'
// Add a document with the admin user's UID as the document ID
{
  email: "admin@chingu.com",
  createdAt: <timestamp>,
  permissions: ["send_broadcast"]
}
```

#### Usage Examples

**1. Send to all users:**
```dart
// In your Flutter app
final result = await FirebaseFunctions.instance
    .httpsCallable('sendBroadcast')
    .call({
  'title': '系統通知',
  'body': '本週活動已開放報名!',
  'targetAll': true,
  'data': {
    'type': 'announcement',
    'action': 'open_events'
  }
});
```

**2. Send to specific cities:**
```dart
final result = await FirebaseFunctions.instance
    .httpsCallable('sendBroadcast')
    .call({
  'title': '台北活動通知',
  'body': '台北本週晚餐聚會開放報名',
  'targetCities': ['taipei'],
  'imageUrl': 'https://example.com/event-image.jpg'
});
```

**3. Send to specific users:**
```dart
final result = await FirebaseFunctions.instance
    .httpsCallable('sendBroadcast')
    .call({
  'title': '個人通知',
  'body': '您的帳戶需要更新資料',
  'targetUserIds': ['user_id_1', 'user_id_2'],
  'data': {
    'type': 'account_update',
    'deeplink': '/profile'
  }
});
```

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `title` | String | Yes | Notification title |
| `body` | String | Yes | Notification body text |
| `targetAll` | Boolean | No | Send to all users (uses 'all_users' topic) |
| `targetCities` | String[] | No | Send to users in specific cities |
| `targetUserIds` | String[] | No | Send to specific user IDs |
| `imageUrl` | String | No | URL of image to display in notification |
| `data` | Map | No | Custom data payload for the notification |

#### Response

```typescript
{
  success: boolean,
  successCount: number,  // Number of successfully sent messages
  failureCount: number,  // Number of failed messages
  totalTargets: number   // Total number of targeted users
}
```

#### Error Handling

The function throws `HttpsError` with the following codes:
- `unauthenticated`: User is not signed in
- `permission-denied`: User is not an admin
- `invalid-argument`: Missing required fields or invalid targeting
- `not-found`: No users found with the specified criteria
- `internal`: Server error during notification sending

## Testing Locally

### 1. Start Firebase Emulator
```bash
npm run serve
```

### 2. Call Function from Flutter
```dart
// Use emulator in development
FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);

// Then call the function as usual
final result = await FirebaseFunctions.instance
    .httpsCallable('sendBroadcast')
    .call({...});
```

## Monitoring

### View Logs
```bash
npm run logs
```

### Check Broadcast History
All broadcasts are logged in the `broadcast_logs` Firestore collection:

```javascript
{
  title: "通知標題",
  body: "通知內容",
  targetType: "all" | "users" | "cities",
  targetIds: [...], // For users or cities targeting
  sentBy: "admin_uid",
  sentAt: <timestamp>,
  successCount: 150,
  failureCount: 5
}
```

## Security Considerations

1. **Admin Verification**: Only users in the `admins` collection can call this function
2. **Rate Limiting**: Consider adding rate limiting to prevent abuse
3. **Token Management**: Invalid FCM tokens are automatically filtered out
4. **Logging**: All broadcasts are logged for audit purposes

## Future Enhancements

- [ ] Add rate limiting per admin
- [ ] Support scheduling broadcasts for future delivery
- [ ] Add A/B testing capabilities
- [ ] Support for rich media notifications
- [ ] Analytics integration for notification engagement
