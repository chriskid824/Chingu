# App Store Screenshots Plan

## Required Screenshots
We need to capture the following screens for both iOS (6.5" and 5.5" display sizes) and Android (Phone and Tablet).

### 1. Matching Screen (Discovery)
*   **Purpose:** Show the core swiping interface.
*   **Content:** A high-quality profile card with a user photo, name, age, and interests.
*   **Caption:** "Swipe to Meet New Friends" / "滑動配對，認識新朋友"

### 2. Events List (Social)
*   **Purpose:** Showcase the dinner events feature.
*   **Content:** A list of attractive dinner events with restaurant images and dates.
*   **Caption:** "Join Exclusive Dinner Events" / "參加精選晚餐聚會"

### 3. Event Detail (Engagement)
*   **Purpose:** Detail view of an event to show richness.
*   **Content:** An event page with "Join" button, participants list, and restaurant details.
*   **Caption:** "Share a Meal, Share a Story" / "共享美食，分享故事"

### 4. Chat Screen (Communication)
*   **Purpose:** Demonstrate communication features.
*   **Content:** A conversation view with text, emojis, and maybe a voice message or sticker.
*   **Caption:** "Connect Instantly" / "即時聊天，輕鬆約飯"

### 5. Profile Screen (Personalization)
*   **Purpose:** Show user identity and stats.
*   **Content:** A completed user profile with moments/posts or stats.
*   **Caption:** "Express Yourself" / "展現獨特自我"

## Technical Instructions for Generating Screenshots

Since this is a Flutter app, we can use `flutter_driver` or `integration_test` to automate this, or manually run the app on simulators.

**Manual Method (Recommended for specific framing):**
1.  Launch the iOS Simulator (iPhone 14 Pro Max for 6.5").
2.  Run the app: `flutter run`
3.  Navigate to each screen.
4.  Use `Cmd + S` in Simulator to save screenshots to Desktop.
5.  Repeat for Android Emulator (Pixel 6 Pro).

**Design Polish:**
*   Wrap screenshots in device frames (mockups).
*   Add short caption text above the device.
*   Use a consistent background color or gradient matching the brand (Chingu Orange).
