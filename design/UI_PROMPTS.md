# Chingu App - UI 生成 Prompts

本文檔包含所有 36 個介面的 Stitch AI / Claude / ChatGPT 生成 prompts。

## 全局設計規範

**配色方案**:
- 主色: #FF6B35 (溫暖橙色)
- 次要色: #004E89 (深藍色)
- 背景色: #F7F7F7
- 文字色: #2D3142
- 成功色: #06A77D
- 警告色: #F4D35E

**字型**: Noto Sans TC (中文), Roboto (英文)

---

## 📱 認證流程 (5個介面)

### 1. 啟動頁面 (Splash Screen)

```
Create a Flutter splash screen for a social dinner app called "Chingu". 
Design requirements:
- Centered app logo with a simple food/dining icon
- App name "Chingu" below the logo in a modern sans-serif font
- Warm color scheme with orange (#FF6B35) gradient background
- Circular progress indicator at the bottom
- Fade-in animation for the logo
- Minimum display time: 2 seconds
- Modern, clean, and welcoming design
```

**文件路徑**: `lib/design/auth/splash_screen.dart`

---

### 2. 登入頁面 (Login Screen)

```
Create a Flutter login screen for Chingu social dinner app.
Components needed:
- App logo at top
- Welcome text "歡迎回來" (Welcome Back)
- Email input field with validation
- Password input field with show/hide toggle
- "登入" (Login) button with primary orange color
- Google Sign-In button with Google logo
- "忘記密碼?" (Forgot Password) link
- "還沒有帳號？立即註冊" (Don't have an account? Sign up) link at bottom
- Gradient background from top to bottom
- Input fields with rounded corners
- Proper spacing and padding
- Loading state with circular indicator
```

**文件路徑**: `lib/design/auth/login_screen.dart`

---

### 3. 註冊頁面 (Register Screen)

```
Create a Flutter registration screen for Chingu app.
Form fields needed:
- Email input with email validation
- Password input with strength indicator
- Confirm password input
- Name input field
- "註冊" (Register) button
- "已有帳號？登入" (Already have account? Login) link
- Terms and conditions checkbox
- Loading state
- Back button in app bar
- Scrollable form with proper validation
- Error messages in Chinese
```

**文件路徑**: `lib/design/auth/register_screen.dart`

---

### 4. 忘記密碼頁面 (Forgot Password Screen)

```
Create a Flutter forgot password screen.
Components:
- Illustration or icon showing password reset
- Instruction text "請輸入您的電子郵件，我們將發送重置連結"
- Email input field
- "發送重置連結" (Send Reset Link) button
- "返回登入" (Back to Login) link
- Success message display area
- Loading state
- Clean and simple design
```

**文件路徑**: `lib/design/auth/forgot_password_screen.dart`

---

### 5. 性格測試頁面 (Personality Test Screen)

```
Create a Flutter personality test screen with multiple questions.
Features:
- Progress indicator at top showing X/20 questions
- Question card in center with shadow
- Question number and text
- 4-5 multiple choice options as rounded buttons
- "上一題" (Previous) and "下一題" (Next) navigation buttons
- "提交" (Submit) button on last question
- Smooth page transition animation
- Option selection with visual feedback
- Skip button (optional)
- Progress saved automatically
```

**文件路徑**: `lib/design/auth/personality_test_screen.dart`

---

## 📱 個人資料模組 (4個介面)

### 6. 新手引導頁面 (Onboarding Screen)

```
Create a Flutter multi-step onboarding form with 4 pages.
Page 1 - Basic Info:
- Name input
- Age input (number picker)
- Gender selection (男/女/其他)

Page 2 - Location & Career:
- Job/occupation input
- City dropdown
- District dropdown

Page 3 - Interests:
- Grid of interest tags (can select multiple)
- Tags: 旅遊, 美食, 音樂, 運動, 電影, 閱讀, 藝術, 科技等

Page 4 - Preferences:
- Budget range slider (100-2000)
- Preferred match type (男性/女性/不限)
- Age range preference (min-max slider)

Design features:
- Stepper indicator at top (1/4, 2/4, etc.)
- "下一步" (Next) and "上一步" (Back) buttons
- "跳過" (Skip) button
- Smooth page transitions
- Form validation
- Save progress
```

**文件路徑**: `lib/design/profile/onboarding_screen.dart`

---

### 7. 個人資料頁面 (Profile Screen)

```
Create a Flutter user profile screen.
Layout sections:
- Header with gradient background
- Circular profile photo (with edit icon overlay)
- Name, age, and occupation
- Location (city, district)
- Statistics row: "參加晚餐 X 次 | 配對成功 Y 次"
- About/Bio section
- Interests tags (wrapped in chips)
- Budget range display
- Match preferences display
- "編輯個人資料" (Edit Profile) button
- Settings icon in app bar

Design:
- Card-based layout with shadows
- Warm color scheme
- Scrollable content
- Clean and modern
```

**文件路徑**: `lib/design/profile/profile_screen.dart`

---

### 8. 編輯個人資料頁面 (Edit Profile Screen)

```
Create a Flutter edit profile form screen.
Editable fields:
- Profile photo upload/change button
- Name
- Age (number picker)
- Gender
- Job/occupation
- City and district
- Bio/self-introduction (multi-line text, 100-300 characters)
- Interests selection
- Budget range slider
- Match preferences (gender, age range)

Features:
- "儲存" (Save) button in app bar
- "取消" (Cancel) back button
- Character counter for bio
- Form validation
- Loading state when saving
- Success/error snackbar messages
- Photo picker bottom sheet
```

**文件路徑**: `lib/design/profile/edit_profile_screen.dart`

---

### 9. 個人簡介頁面 (Bio Screen)

```
Create a Flutter bio editing screen.
Components:
- Multi-line text input for self-introduction
- Character counter (100-300 characters)
- Placeholder text with suggestions
- "儲存" (Save) button
- Preview of how bio appears to others
- Tips section with good bio examples
- Word count and character count
- Simple and focused design
```

**文件路徑**: `lib/design/profile/bio_screen.dart`

---

## 📱 首頁與導航 (4個介面)

### 10. 主頁面 (Main Screen with Bottom Navigation)

```
Create a Flutter main screen with bottom navigation bar.
Bottom navigation tabs (4 items):
1. 首頁 (Home) - home icon
2. 預約 (Booking) - calendar icon
3. 訊息 (Messages) - message icon
4. 設定 (Settings) - settings icon

Features:
- Selected tab highlighted in orange
- Unselected tabs in gray
- Icon with label
- Badge for unread messages count
- Smooth tab switching
- IndexedStack to preserve state
- Material Design 3 style
```

**文件路徑**: `lib/design/home/main_screen.dart`

---

### 11. 首頁動態頁面 (Home Feed Screen)

```
Create a Flutter home feed screen for social dinner app.
Sections from top to bottom:
1. User profile card (compact):
   - Avatar, name, "查看個人資料" button

2. Weekly dinner signup card:
   - "本週三晚餐" title
   - Date and time
   - "立即報名" (Sign up) button
   - Participant count

3. Recommended matches carousel:
   - Horizontally scrollable user cards
   - Swipe left/right
   - User photo, name, age, matching score

4. Upcoming events section:
   - Event cards with restaurant, date, participants
   - Status badges

5. Past events list:
   - Compact list items
   - Tap to view details

Design:
- Gradient header
- Card-based layout
- Pull to refresh
- Scroll to top button
- Empty states
```

**文件路徑**: `lib/design/home/home_feed_screen.dart`

---

### 12. 通知頁面 (Notifications Screen)

```
Create a Flutter notifications list screen.
Notification types:
- Match notifications (配對通知)
- Message notifications (訊息通知)
- Event reminders (活動提醒)
- System notifications (系統通知)

Each notification item shows:
- Icon based on type
- Title and description
- Timestamp (e.g., "2小時前")
- Read/unread indicator (dot for unread)
- Tap to navigate to relevant screen

Features:
- "標記全部已讀" (Mark all as read) button
- "清除所有" (Clear all) button
- Swipe to delete
- Group by date (今天, 昨天, 更早)
- Empty state when no notifications
- Pull to refresh
```

**文件路徑**: `lib/design/home/notifications_screen.dart`

---

### 13. 探索頁面 (Explore Screen)

```
Create a Flutter explore/discover users screen.
Components:
- Search bar at top
- Filter chips below search:
  - 年齡 (Age)
  - 興趣 (Interests)
  - 地區 (Location)
  - 預算 (Budget)
- Filter bottom sheet when chip tapped
- User cards in grid (2 columns):
  - User photo
  - Name, age
  - Occupation
  - Top 3 interests as small chips
  - Match score percentage
- "查看更多" (View more) on card tap
- Floating filter button
- Pagination/infinite scroll
- Empty state if no results
```

**文件路徑**: `lib/design/home/explore_screen.dart`

---

## 📱 配對模組 (5個介面)

### 14. 瀏覽用戶頁面 (Browse Users Screen - Tinder Style)

```
Create a Flutter Tinder-style card swiping screen.
Features:
- Stack of user cards (show 2-3 cards at once)
- Each card displays:
  - Large user photo (full card background)
  - Gradient overlay at bottom
  - Name, age, occupation
  - Distance (e.g., "5km away")
  - Top 3 interests
  - Match compatibility score
- Swipe gestures:
  - Swipe right = like (green indicator)
  - Swipe left = pass (red indicator)
  - Visual feedback during swipe
- Bottom action buttons:
  - Pass button (X icon, red)
  - Info button (i icon)
  - Like button (heart icon, green)
- Card stack animation
- Empty state when no more users
- Undo last swipe button (optional)
```

**文件路徑**: `lib/design/matching/browse_users_screen.dart`

---

### 15. 用戶詳情頁面 (User Detail Screen)

```
Create a Flutter user detail/full profile screen.
Layout:
- Large profile photo at top (scrollable header)
- Basic info card:
  - Name, age, gender
  - Occupation
  - Location
- Bio/About section
- Interests section (wrapped chips)
- Match compatibility breakdown:
  - Personality: 85%
  - Interests: 70%
  - Age preference: 90%
  - Overall score
- Photos gallery (if multiple photos)
- "發送配對邀請" (Send match request) floating button
- Back button
- Report/block options in menu

Design:
- Scrollable content
- Card-based sections
- Visual charts for compatibility
- Clean and informative
```

**文件路徑**: `lib/design/matching/user_detail_screen.dart`

---

### 16. 配對請求頁面 (Match Requests Screen)

```
Create a Flutter match requests management screen.
Two tabs:
1. 收到的請求 (Received Requests)
2. 已發送的請求 (Sent Requests)

Received requests list items:
- User avatar
- Name, age, occupation
- "X天前" timestamp
- Match score
- Accept (green) and Decline (red) buttons
- Expired indicator if >48 hours

Sent requests list items:
- User avatar
- Name, age
- Status: 等待中 (Pending) / 已接受 (Accepted) / 已拒絕 (Declined)
- Sent timestamp
- Cancel button for pending

Features:
- Badge showing unread count on tab
- Empty state for each tab
- Pull to refresh
- Swipe actions
- Confirmation dialog for accept/decline
```

**文件路徑**: `lib/design/matching/match_requests_screen.dart`

---

### 17. 配對成功頁面 (Match Success Screen)

```
Create a Flutter match success celebration screen.
Components:
- Confetti or celebration animation
- "配對成功！" (Match Success!) large title
- Two user avatars side by side or overlapping
- Matched user names
- "你們配對成功了！" message
- Match score/compatibility display
- Two action buttons:
  - "開始聊天" (Start chatting) - primary
  - "查看活動詳情" (View event details) - secondary
- Animated entrance
- Haptic feedback
- Auto-navigate to chat after 3 seconds (with countdown)

Design:
- Bright and celebratory
- Centered content
- Can dismiss with back button
```

**文件路徑**: `lib/design/matching/match_success_screen.dart`

---

### 18. 群組配對頁面 (Group Matching Screen)

```
Create a Flutter group match result screen showing 4-6 people matched for dinner.
Layout:
- "配對成功！" title
- "你將和以下朋友共進晚餐" subtitle
- Grid of matched members (2x3 or 2x2):
  - Avatar
  - Name, age
  - Brief info (occupation or top interest)
- Match explanation card:
  - "為什麼配對?" section
  - Compatibility reasons in bullet points
- Event info preview:
  - Suggested date/time
  - Budget range
- Action buttons:
  - "確認參加" (Confirm) - green, primary
  - "無法參加" (Decline) - gray, outline
- Timer showing "請在24小時內確認"
- "開始群聊" button after confirmation

Design:
- Card-based layout
- Member photos in circles
- Clear call-to-action
- Warm and inviting
```

**文件路徑**: `lib/design/matching/group_matching_screen.dart`

---

## 📱 預約/活動模組 (6個介面)

### 19. 預約頁面 (Booking Screen)

```
Create a Flutter booking/events main screen.
Sections:
1. Weekly dinner signup card (prominent):
   - "本週三晚餐" title
   - Date: 2024年1月10日 19:00
   - Current signups: "已有12人報名"
   - "我要參加" button
   - Countdown timer

2. Create custom event button:
   - "+ 創建私人聚會" button with icon

3. My events tabs:
   - 即將到來 (Upcoming) tab
   - 過去的 (Past) tab

4. Event list items showing:
   - Restaurant name
   - Date and time
   - Participant avatars (overlapping circles)
   - Status badge (已確認/等待中/已完成)
   - Tap to view details

Features:
- Pull to refresh
- Filter/sort options
- Empty state for each tab
- Calendar view toggle option
```

**文件路徑**: `lib/design/events/booking_screen.dart`

---

### 20. 創建活動頁面 (Create Event Screen)

```
Create a Flutter create custom dinner event form.
Form fields:
- Event title (optional)
- Date picker with calendar
- Time picker
- Number of participants (2-6 selector)
- Event type/theme selection:
  - 休閒聚餐 (Casual)
  - 商務交流 (Business)
  - 素食聚會 (Vegetarian)
  - 興趣主題 (Interest-based)
- Budget range per person slider (100-2000)
- Cuisine preference multi-select chips
- Special requirements text area
- Restaurant preference (optional):
  - Let system suggest
  - Choose specific restaurant
- "創建活動" (Create Event) button

Design:
- Scrollable form
- Section dividers
- Input validation
- Preview of selections
- Loading state
- Success confirmation
```

**文件路徑**: `lib/design/events/create_event_screen.dart`

---

### 21. 活動詳情頁面 (Event Detail Screen)

```
Create a Flutter event details screen.
Information sections:
1. Header card:
   - Event status badge
   - Restaurant name (if decided)
   - Date and time (large, prominent)
   - Countdown if upcoming

2. Location card:
   - Restaurant name
   - Address
   - Small map preview
   - "導航" (Navigate) button
   - "電話" (Call) button

3. Participants section:
   - Avatar circles with names
   - Confirmation status for each
   - "已確認 X/Y 人"

4. Event details:
   - Budget per person
   - Event type/theme
   - Special notes

5. Icebreaker questions preview:
   - "破冰問題" section
   - Show 2-3 questions
   - "查看更多" link

6. Action buttons:
   - "開啟聊天室" (Open chat)
   - "邀請朋友" (Invite friends)
   - "取消參加" (Cancel) - if upcoming
   - "評價活動" (Review) - if completed

Design:
- Card-based sections
- Scrollable
- Sticky action buttons at bottom
- Status-dependent UI
```

**文件路徑**: `lib/design/events/event_detail_screen.dart`

---

### 22. 餐廳選擇器頁面 (Restaurant Picker Screen)

```
Create a Flutter restaurant selection screen.
Features:
- Map view showing nearby restaurants
- Toggle between map and list view
- Filter bar:
  - Cuisine type chips
  - Price range ($/$$/$$$)
  - Distance slider
  - Rating filter

Restaurant list items:
- Restaurant photo
- Name
- Cuisine type
- Price level ($$)
- Rating stars and review count
- Distance from user
- "投票" (Vote) button for group decision
- Current votes count if group event

Group voting features:
- Vote count display
- Real-time updates
- Top voted highlighted
- Confirm selection button (only organizer)

Detail view:
- Photos
- Address
- Phone
- Operating hours
- Menu preview
- Reviews

Design:
- Map/list toggle smooth transition
- Loading skeleton screens
- Empty state if no restaurants
```

**文件路徑**: `lib/design/events/restaurant_picker_screen.dart`

---

### 23. 破冰遊戲頁面 (Icebreaker Screen)

```
Create a Flutter icebreaker questions screen.
Layout:
- Carousel/card swiper showing questions
- Category tabs at top:
  - 輕鬆有趣 (Fun)
  - 深度探討 (Deep)
  - 創意思考 (Creative)
  - 隨機 (Random)

Question card design:
- Large card with shadow
- Question text centered
- Question number (1/20)
- Category tag
- Example answer (expandable)
- "收藏" (Favorite) button
- "分享" (Share) button

Navigation:
- Swipe left/right to change questions
- Navigation dots at bottom
- "隨機一題" (Random) button
- "下一題" (Next) button

Features:
- Smooth card animations
- Save favorites
- Used questions marked
- Refresh to get new questions
- Copy question text

Design:
- Playful and engaging
- Large readable text
- Colorful category indicators
```

**文件路徑**: `lib/design/events/icebreaker_screen.dart`

---

### 24. 活動評價頁面 (Event Review Screen)

```
Create a Flutter event review/rating screen.
Rating sections:
1. Overall experience:
   - 5 star rating selector (large, tappable)
   - "整體體驗如何？"

2. Rate participants individually:
   - List of participants
   - Each with:
     - Avatar and name
     - 5 star rating
     - "願意再次配對" checkbox

3. Restaurant rating:
   - 5 stars
   - Quick tags: 好吃, 環境好, 服務佳, 價格合理

4. Feedback text area:
   - "分享你的體驗" (Share your experience)
   - Placeholder with prompt
   - 200 character limit

5. Suggestions (optional):
   - "有什麼建議嗎？"

Action buttons:
- "提交評價" (Submit) - prominent
- "跳過" (Skip) link

Features:
- Can't submit without overall rating
- Anonymous feedback option
- Thank you screen after submission
- Rating affects future matching

Design:
- Clean and friendly
- Easy to complete
- Progress indicator
- Positive reinforcement
```

**文件路徑**: `lib/design/events/event_review_screen.dart`

---

## 📱 聊天模組 (3個介面)

### 25. 聊天列表頁面 (Chat List Screen)

```
Create a Flutter chat list screen.
Chat list items show:
- Group avatar (if group chat) or user avatar
- Chat name (event name or user name)
- Last message preview (truncated)
- Timestamp (relative, e.g., "5分鐘前")
- Unread message count badge (if unread)
- Online status indicator (green dot)
- Pinned indicator (if pinned)

Features:
- Search bar at top
- Pull to refresh
- Swipe actions:
  - Pin/unpin
  - Mute notifications
  - Delete chat
- Long press for batch selection
- Empty state: "還沒有對話"
- Group chats section separator
- Sort by: Recent / Unread / Pinned

Design:
- Clean list layout
- Message preview in gray
- Unread chats have bold text
- Smooth animations
```

**文件路徑**: `lib/design/chat/chat_list_screen.dart`

---

### 26. 聊天室頁面 (Chat Room Screen)

```
Create a Flutter chat room screen with messaging.
Chat UI components:
- App bar showing:
  - Back button
  - Chat avatar and name
  - Participant count (for groups)
  - Info button (navigate to group info)
  
- Message bubbles:
  - Sent messages: right-aligned, blue/orange
  - Received messages: left-aligned, gray
  - Sender name (in group chats)
  - Timestamp
  - Read receipts (double check marks)
  - Message status (sending/sent/delivered/read)

- Input area at bottom:
  - Text input field with rounded corners
  - Send button (icon)
  - Attachment button (paperclip icon)
  - Emoji picker button
  - Photo/camera button

Message types support:
- Text messages
- Images (with preview)
- Location sharing
- System messages (user joined/left)

Features:
- Scroll to bottom button
- Load more messages on scroll up
- Typing indicator "XXX 正在輸入..."
- Long press message for options (copy/delete)
- Date separators
- Link preview
- Haptic feedback on send

Design:
- Modern chat UI
- Smooth animations
- Message grouping
- Keyboard handling
```

**文件路徑**: `lib/design/chat/chat_room_screen.dart`

---

### 27. 群組資訊頁面 (Group Info Screen)

```
Create a Flutter group chat info/settings screen.
Sections:
1. Group header:
   - Group event name
   - Event date and location
   - "查看活動詳情" link

2. Members list:
   - Grid or list of participants
   - Avatar, name, status (confirmed/pending)
   - Organizer badge

3. Media/Files:
   - Grid of shared photos
   - "查看全部" (View all) button

4. Group settings:
   - Notifications toggle
   - Mute duration selector
   - Custom notifications

5. Actions:
   - "查看活動詳情" button
   - "退出群組" (Leave group) button (destructive)
   - "封鎖/檢舉" (Block/Report) in menu

Features:
- Scrollable content
- Confirmation dialogs for destructive actions
- Admin controls if user is organizer
- Member tap to view profile

Design:
- Card-based sections
- Clean and organized
- Settings toggles
- Destructive actions in red
```

**文件路徑**: `lib/design/chat/group_info_screen.dart`

---

## 📱 設定模組 (6個介面)

### 28. 設定主頁面 (Settings Screen)

```
Create a Flutter settings main screen.
Settings menu items grouped by sections:

帳號設定 (Account):
- 個人資料 (Profile) - arrow right
- 帳號管理 (Account Management) - arrow right

偏好設定 (Preferences):
- 配對偏好 (Match Preferences) - arrow right
- 通知設定 (Notifications) - arrow right
- 隱私設定 (Privacy) - arrow right

訂閱與付費 (Subscription):
- 訂閱方案 (Subscription Plan) - arrow right
- 交易記錄 (Transaction History) - arrow right

其他 (Others):
- 關於 Chingu (About) - arrow right
- 使用條款 (Terms of Service) - arrow right
- 隱私政策 (Privacy Policy) - arrow right
- 聯絡客服 (Contact Support) - arrow right
- 版本資訊 (Version) - displays version number

底部:
- "登出" (Logout) button (destructive, red)

Design:
- Grouped list with headers
- Icons for each item
- Chevron arrows for navigation
- Section dividers
- Tappable list items
- Logout confirmation dialog
```

**文件路徑**: `lib/design/settings/settings_screen.dart`

---

### 29. 通知設定頁面 (Notification Settings Screen)

```
Create a Flutter notification settings screen.
Toggle switches for:

推播通知 (Push Notifications):
- 啟用推播通知 (Enable Push) - master switch
- 配對通知 (Match Notifications)
- 訊息通知 (Message Notifications)
- 活動提醒 (Event Reminders)
  - 活動前24小時
  - 活動前1小時
  - 活動開始時
- 系統公告 (System Announcements)

Email 通知:
- 週報摘要 (Weekly Summary)
- 活動更新 (Event Updates)
- 配對建議 (Match Suggestions)

免打擾模式 (Do Not Disturb):
- 啟用時間段選擇器
- 開始時間
- 結束時間

Features:
- All toggles save automatically
- Visual feedback on toggle
- Descriptions under each option
- Request notification permission if disabled
- Link to system settings if denied

Design:
- List of toggle switches
- Section headers
- Helper text in gray
- Smooth toggle animations
```

**文件路徑**: `lib/design/settings/notification_settings_screen.dart`

---

### 30. 隱私設定頁面 (Privacy Settings Screen)

```
Create a Flutter privacy settings screen.
Privacy options:

個人資料可見度 (Profile Visibility):
- Radio buttons:
  - 公開 (Public) - everyone can see
  - 僅配對好友 (Matched Friends Only)
  - 私密 (Private)

位置分享 (Location Sharing):
- 顯示精確位置 toggle
- 顯示大約距離 toggle
- 僅在活動期間分享 toggle

活動歷史 (Activity History):
- 顯示參加過的活動 toggle
- 顯示評價 toggle

配對設定 (Matching Settings):
- 誰可以發送配對邀請:
  - 所有人 (Everyone)
  - 符合偏好的用戶 (Preference matched users)
  - 無 (None - only system matching)

封鎖列表 (Blocked List):
- "管理封鎖列表" button
- Shows count of blocked users

Features:
- Settings save automatically
- Explanation text under each option
- Warning messages for restrictive settings
- Blocked list screen on tap

Design:
- Toggle switches and radio buttons
- Section headers
- Helper descriptions
- Warning colors for sensitive options
```

**文件路徑**: `lib/design/settings/privacy_settings_screen.dart`

---

### 31. 帳號管理頁面 (Account Management Screen)

```
Create a Flutter account management screen.
Account actions:

連結帳號 (Linked Accounts):
- Email: user@example.com (verified/unverified)
- Google: Connected / "連結" button
- Phone: +886 912345678 or "新增" button

安全性 (Security):
- "更改密碼" (Change Password) button
- "手機號碼驗證" (Phone Verification) button
- "雙重驗證" (Two-Factor Auth) toggle

資料管理 (Data Management):
- "下載我的資料" (Download My Data) button
- "清除快取" (Clear Cache) button - shows cache size

危險區域 (Danger Zone) - red background:
- "暫停帳號" (Pause Account) button
- "刪除帳號" (Delete Account) button - most destructive

Features:
- Confirmation dialogs for destructive actions
- Password change modal
- Verification code input for phone
- Data download generates report
- Delete account requires password re-entry

Design:
- Grouped sections
- Danger zone visually separated with red
- Confirmation dialogs with warnings
- Loading states
```

**文件路徑**: `lib/design/settings/account_management_screen.dart`

---

### 32. 訂閱管理頁面 (Subscription Screen)

```
Create a Flutter subscription/premium plans screen.
Current plan card:
- "目前方案" (Current Plan)
- Free / Premium tier
- Benefits list
- Valid until date (if premium)
- "續訂" (Renew) or "升級" (Upgrade) button

Plans comparison:
免費方案 (Free Plan):
- 每月參加2次晚餐
- 基本配對
- 有限聊天功能
- 價格: 免費

進階方案 (Premium Plan):
- 無限晚餐參加次數
- 進階配對演算法
- 優先配對
- 無限聊天
- 專屬活動
- 查看誰喜歡你
- 價格: NT$299/月 或 NT$2,499/年 (省30%)

Features:
- Toggle between monthly/yearly
- "選擇方案" (Select Plan) buttons
- Payment method selection
- Subscription benefits icons
- Transaction history link
- "取消訂閱" (Cancel Subscription) button for premium users

Design:
- Card-based plans
- Highlighted premium plan
- Price comparison
- Feature checkmarks
- Smooth animations
- Payment sheet integration
```

**文件路徑**: `lib/design/settings/subscription_screen.dart`

---

### 33. 關於頁面 (About Screen)

```
Create a Flutter about app screen.
Content sections:

App Info:
- Chingu logo
- App name and version (v1.0.0)
- Tagline: "讓每一次晚餐都有意義"

Links:
- "使用條款" (Terms of Service) - opens web view
- "隱私政策" (Privacy Policy) - opens web view
- "常見問題" (FAQ) - opens FAQ screen
- "聯絡我們" (Contact Us) - email/form
- "評價應用" (Rate App) - opens app store

Social Media:
- Instagram icon and link
- Facebook icon and link
- Website link

Credits:
- "開發團隊" (Development Team)
- Third-party libraries/licenses

Features:
- Tappable list items
- Opens links in in-app browser or external browser
- Email compose for contact
- App store rating integration
- Share app button

Design:
- Centered logo at top
- Grouped sections
- External link icons
- Clean and simple
- Footer with copyright
```

**文件路徑**: `lib/design/settings/about_screen.dart`

---

## 📱 其他功能介面 (3個介面)

### 34. 緊急支援頁面 (Emergency Support Screen)

```
Create a Flutter emergency support screen.
Emergency options (large, tappable cards):

1. 聯絡緊急聯絡人 (Call Emergency Contact):
   - Phone icon
   - Subtitle: "立即撥打您設定的緊急聯絡人"
   - Shows contact name and number
   - One tap to call

2. 分享即時位置 (Share Live Location):
   - Location icon
   - Subtitle: "向緊急聯絡人分享位置"
   - Duration selector (30分鐘 / 1小時 / 直到取消)
   - "開始分享" button

3. 聯絡客服 (Contact Support):
   - Support icon
   - Subtitle: "24/7客服支援"
   - Opens chat with support

4. 取消活動參加 (Cancel Event Participation):
   - Calendar icon
   - Subtitle: "緊急取消當前活動"
   - Shows current event
   - "取消參加" button

Quick access:
- 報警 (Call Police) - shows local emergency number
- "我很安全" (I'm Safe) button to dismiss

Features:
- Quick actions without navigation
- One-tap emergency contacts
- Location sharing with map
- Confirmation dialogs
- Notification to matched users if cancel event

Design:
- Large, easy to tap buttons
- Red accent for emergency
- Clear hierarchy
- Minimal steps
- Accessible design
```

**文件路徑**: `lib/design/common/emergency_support_screen.dart`

---

### 35. 載入頁面 (Loading Screen / States)

```
Create reusable Flutter loading components and screens.
Loading variations:

1. Full screen loading:
   - Chingu logo or icon
   - Rotating/pulsing animation
   - Loading text: "載入中..." / "請稍候..."
   - Optional progress percentage

2. Inline loading:
   - Circular progress indicator
   - Can be placed in any widget
   - Small, medium, large sizes

3. Skeleton screens:
   - For user lists: shimmer effect
   - For cards: animated placeholder rectangles
   - For images: gray box with shimmer

4. Pull to refresh:
   - Custom refresh indicator
   - Chingu themed
   - Smooth animation

5. Button loading states:
   - Spinner replaces button text
   - Button disabled during loading
   - Width doesn't change

Features:
- Smooth animations
- Shimmer effect for skeletons
- Timeout handling
- Error state if loading fails

Design:
- Brand colors
- Consistent across app
- Not blocking user too long
- Progress indication where possible
```

**文件路徑**: `lib/design/common/loading_screen.dart`

---

### 36. 錯誤頁面 (Error Screen / States)

```
Create Flutter error handling screens and widgets.
Error types:

1. Network error:
   - No wifi icon
   - "無法連接網路" (No network connection)
   - "請檢查網路連線" description
   - "重試" (Retry) button

2. Server error:
   - Server icon
   - "伺服器錯誤" (Server error)
   - "請稍後再試"
   - "重試" button
   - "回到首頁" button

3. Not found (404):
   - Confused emoji or icon
   - "找不到頁面" (Page not found)
   - "您要找的內容不存在"
   - "回到首頁" button

4. Permission denied:
   - Lock icon
   - "需要權限" (Permission required)
   - Explanation of what permission and why
   - "前往設定" (Go to Settings) button

5. Empty state (no data):
   - Relevant illustration
   - "暫無內容" (No content)
   - Contextual message
   - Optional action button

6. Inline error (form validation):
   - Red text under input
   - Error icon
   - Clear error message
   - Shake animation on invalid submit

Features:
- Contextual error messages
- Retry functionality
- Navigation options
- Friendly tone
- Helpful suggestions
- Log errors for debugging

Design:
- Illustrations or icons
- Not too alarming
- Clear call-to-action
- Consistent error styling
- Red for critical errors
- Yellow/orange for warnings
```

**文件路徑**: `lib/design/common/error_screen.dart`

---

## 使用說明

### 如何使用這些 Prompts:

1. **直接使用**: 複製任何一個 prompt 到 AI 代碼生成工具
2. **客製化**: 根據需求修改配色、文案或功能
3. **組合使用**: 可以組合多個相關介面的 prompt
4. **迭代優化**: 生成後根據實際需求調整代碼

### 建議的生成順序:

1. 先創建設計系統和主題配置
2. 生成主導航和底部導航欄
3. 按模組逐一生成介面
4. 最後調整樣式一致性

### 推薦工具:

- **Stitch AI**: Flutter UI 生成
- **Claude / ChatGPT**: 代碼生成和優化
- **Figma**: 視覺化設計原型
- **FlutterFlow**: 可視化開發（可選）

### 注意事項:

- 生成的代碼需要手動調整和優化
- 確保所有介面使用統一的設計系統
- 添加適當的錯誤處理和邊界情況
- 測試不同螢幕尺寸的響應式設計
- 添加無障礙功能支援

---

最後更新: 2024/10/13
版本: 1.0.0

