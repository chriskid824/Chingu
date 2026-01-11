# Firestore Security Rules Test Plan

## Overview
This document outlines the test strategy for verifying the Firestore security rules (`firestore.rules`). Since the local environment lacks the Firestore Emulator Suite, these tests are designed to be run in the Firebase Console's "Rules Playground" or a similar simulator environment.

## Test Scenarios

### 1. Users Collection (`/users/{userId}`)

| Test Case | Actor | Operation | Path | Expected Result | Reason |
|-----------|-------|-----------|------|-----------------|--------|
| **Read Own Profile** | User A | GET | `/users/userA` | **ALLOW** | Authenticated users can read. |
| **Read Other Profile** | User A | GET | `/users/userB` | **ALLOW** | Required for Matching/Chat. |
| **Create Own Profile** | User A | CREATE | `/users/userA` | **ALLOW** | `request.auth.uid == userId`. |
| **Create Other Profile** | User A | CREATE | `/users/userB` | **DENY** | `request.auth.uid != userId`. |
| **Update Own Profile** | User A | UPDATE | `/users/userA` | **ALLOW** | `isOwner(userId)`. |
| **Update Other Profile** | User A | UPDATE | `/users/userB` | **DENY** | Not owner. |
| **Delete Own Profile** | User A | DELETE | `/users/userA` | **ALLOW** | `isOwner(userId)`. |
| **Admin Delete Profile** | Admin | DELETE | `/users/userA` | **ALLOW** | `isAdmin()`. |
| **Privilege Escalation (Update)** | User A | UPDATE | `/users/userA` | **DENY** | `diff().affectedKeys().hasAny(['isAdmin'])`. User A tries to set `isAdmin: true`. |
| **Privilege Escalation (Create)** | User A | CREATE | `/users/userA` | **DENY** | `data.keys().hasAny(['isAdmin'])`. User A tries to create profile with `isAdmin: true`. |

### 2. Login History (`/users/{userId}/login_history/{historyId}`)

| Test Case | Actor | Operation | Path | Expected Result | Reason |
|-----------|-------|-----------|------|-----------------|--------|
| **Read Own History** | User A | GET | `/users/userA/login_history/123` | **ALLOW** | `isOwner`. |
| **Read Other History** | User A | GET | `/users/userB/login_history/456` | **DENY** | Not owner. |
| **Create Own History** | User A | CREATE | `/users/userA/login_history/123` | **ALLOW** | `isOwner`. |

### 3. Chat Rooms (`/chat_rooms/{chatRoomId}`)

*Pre-condition: `chatRoom1` has `participantIds: ['userA', 'userB']`.*

| Test Case | Actor | Operation | Path | Expected Result | Reason |
|-----------|-------|-----------|------|-----------------|--------|
| **Read Participant** | User A | GET | `/chat_rooms/chatRoom1` | **ALLOW** | `userA` is in `participantIds`. |
| **Read Non-Participant** | User C | GET | `/chat_rooms/chatRoom1` | **DENY** | `userC` not in `participantIds`. |
| **Create Chat Room** | User A | CREATE | `/chat_rooms/newRoom` | **ALLOW** | Payload includes `userA` in `participantIds`. |
| **Update Chat Room** | User A | UPDATE | `/chat_rooms/chatRoom1` | **ALLOW** | Participant can update (e.g., last message). |

### 4. Messages (`/messages/{messageId}`)

*Pre-condition: `message1` has `chatRoomId: 'chatRoom1'`.*

| Test Case | Actor | Operation | Path | Expected Result | Reason |
|-----------|-------|-----------|------|-----------------|--------|
| **Read Message (Participant)** | User A | GET | `/messages/message1` | **ALLOW** | `userA` is in `chatRoom1` participants. |
| **Read Message (Non-Partic.)** | User C | GET | `/messages/message1` | **DENY** | `userC` is not in `chatRoom1` participants. |
| **Create Message** | User A | CREATE | `/messages/newMsg` | **ALLOW** | `chatRoomId` points to room where `userA` is participant. |
| **Create Message (Spoof)** | User A | CREATE | `/messages/newMsg` | **DENY** | `chatRoomId` points to room where `userA` is NOT participant. |
| **Update Own Message** | User A | UPDATE | `/messages/msgA` | **ALLOW** | `senderId == userA`. |
| **Update Other Message** | User A | UPDATE | `/messages/msgB` | **DENY** | `senderId != userA`. |

### 5. Dinner Events (`/dinner_events/{eventId}`)

| Test Case | Actor | Operation | Path | Expected Result | Reason |
|-----------|-------|-----------|------|-----------------|--------|
| **Read Event** | User A | GET | `/dinner_events/event1` | **ALLOW** | Public read. |
| **Create Event** | User A | CREATE | `/dinner_events/newEvent` | **ALLOW** | Authenticated. |
| **Update Event (Creator)** | User A | UPDATE | `/dinner_events/event1` | **ALLOW** | `creatorId == userA`. |
| **Update Event (Other)** | User B | UPDATE | `/dinner_events/event1` | **DENY** | Not creator. |

### 6. Swipes (`/swipes/{swipeId}`)

| Test Case | Actor | Operation | Path | Expected Result | Reason |
|-----------|-------|-----------|------|-----------------|--------|
| **Read Own Swipe** | User A | GET | `/swipes/swipe1` (userId=A) | **ALLOW** | `userId == A`. |
| **Read Incoming Swipe** | User A | GET | `/swipes/swipe2` (target=A) | **ALLOW** | `targetUserId == A` (Mutual match check). |
| **Read Other Swipe** | User A | GET | `/swipes/swipe3` (B->C) | **DENY** | Irrelevant to A. |
| **Create Swipe** | User A | CREATE | `/swipes/new` | **ALLOW** | `userId == A`. |

### 7. Sensitive Collections

| Test Case | Actor | Operation | Path | Expected Result | Reason |
|-----------|-------|-----------|------|-----------------|--------|
| **Read 2FA Codes** | User A | GET | `/two_factor_codes/code1` | **DENY** | `allow read: false`. |
| **Read Reports** | User A | GET | `/reports/rep1` | **DENY** | Admin only. |
| **Read Reports (Admin)** | Admin | GET | `/reports/rep1` | **ALLOW** | Admin only. |

## Notes
- **Admin Access**: Tested using `token.email == 'test@gmail.com'` or `isAdmin == true` on user profile.
- **Data Integrity**: Rules assume data consistency (e.g., `participantIds` is always an array).
