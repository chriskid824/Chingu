import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'screens/auth/splash_screen_demo.dart';
import 'screens/auth/login_screen_demo.dart';
import 'screens/auth/register_screen_demo.dart';
import 'screens/auth/forgot_password_screen_demo.dart';
import 'screens/auth/email_verification_screen_demo.dart';
import 'screens/profile/profile_setup_screen_demo.dart';
import 'screens/profile/interests_selection_screen_demo.dart';
import 'screens/profile/preferences_screen_demo.dart';
import 'screens/profile/profile_detail_screen_demo.dart';
import 'screens/home/home_screen_demo.dart';
import 'screens/home/notifications_screen_demo.dart';
import 'screens/home/search_screen_demo.dart';
import 'screens/home/bottom_nav_demo.dart';
import 'screens/main_screen_demo.dart';
import 'screens/matching/matching_screen_demo.dart';
import 'screens/matching/user_detail_screen_demo.dart';
import 'screens/matching/matches_list_screen_demo.dart';
import 'screens/matching/filter_screen_demo.dart';
import 'screens/matching/match_success_screen_demo.dart';
import 'screens/events/events_list_screen_demo.dart';
import 'screens/events/event_detail_screen_demo.dart';
import 'screens/events/create_event_screen_demo.dart';
import 'screens/events/event_confirmation_screen_demo.dart';
import 'screens/events/event_rating_screen_demo.dart';
import 'screens/chat/chat_list_screen_demo.dart';
import 'screens/chat/chat_detail_screen_demo.dart';
import 'screens/chat/icebreaker_screen_demo.dart';
import 'screens/settings/settings_screen_demo.dart';
import 'screens/settings/edit_profile_screen_demo.dart';
import 'screens/settings/privacy_settings_screen_demo.dart';
import 'screens/settings/notification_settings_screen_demo.dart';
import 'screens/settings/help_center_screen_demo.dart';
import 'screens/settings/about_screen_demo.dart';
import 'screens/common/loading_screen_demo.dart';
import 'screens/common/error_screen_demo.dart';
import 'screens/common/empty_state_screen_demo.dart';
import 'screens/common/theme_comparison_demo.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeController(),
      child: const ChinguDemoApp(),
    ),
  );
}

class ChinguDemoApp extends StatelessWidget {
  const ChinguDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>().theme;
    return MaterialApp(
      title: 'Chingu UI Demo Gallery',
      theme: theme,
      home: const DemoGalleryScreen(),
    );
  }
}

class DemoGalleryScreen extends StatelessWidget {
  const DemoGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chingu UI Demo Gallery'),
        centerTitle: true,
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 主題對比卡片 - 置頂顯示
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B35), Color(0xFF6366F1)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _nav(context, const ThemeComparisonDemo()),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.palette,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '🎨 主題風格對比',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Text(
                              '橙色 vs 極簡紫色',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _buildSection(
            context,
            title: '🔐 認證模組 (5個)',
            items: [
              _DemoItem('啟動頁面', 'Splash Screen', () => _nav(context, const SplashScreenDemo())),
              _DemoItem('登入頁面', 'Login Screen', () => _nav(context, const LoginScreenDemo())),
              _DemoItem('註冊頁面', 'Register Screen', () => _nav(context, const RegisterScreenDemo())),
              _DemoItem('忘記密碼', 'Forgot Password', () => _nav(context, const ForgotPasswordScreenDemo())),
              _DemoItem('郵件驗證', 'Email Verification', () => _nav(context, const EmailVerificationScreenDemo())),
            ],
          ),
          _buildSection(
            context,
            title: '👤 個人資料模組 (4個)',
            items: [
              _DemoItem('個人資料設定', 'Profile Setup', () => _nav(context, const ProfileSetupScreenDemo())),
              _DemoItem('興趣選擇', 'Interests Selection', () => _nav(context, const InterestsSelectionScreenDemo())),
              _DemoItem('配對偏好', 'Preferences', () => _nav(context, const PreferencesScreenDemo())),
              _DemoItem('個人資料詳情', 'Profile Detail', () => _nav(context, const ProfileDetailScreenDemo())),
            ],
          ),
          _buildSection(
            context,
            title: '🏠 首頁與導航 (4個)',
            items: [
              _DemoItem('首頁', 'Home Screen', () => _nav(context, const HomeScreenDemo())),
              _DemoItem('通知頁面', 'Notifications', () => _nav(context, const NotificationsScreenDemo())),
              _DemoItem('搜尋頁面', 'Search', () => _nav(context, const SearchScreenDemo())),
              _DemoItem('底部導航欄', 'Bottom Navigation', () => _nav(context, const BottomNavDemo())),
              _DemoItem('主程式框架', 'Main App Shell', () => _nav(context, const MainScreenDemo())),
            ],
          ),
          _buildSection(
            context,
            title: '💕 配對模組 (5個)',
            items: [
              _DemoItem('配對頁面', 'Matching Screen', () => _nav(context, const MatchingScreenDemo())),
              _DemoItem('用戶詳情', 'User Detail', () => _nav(context, const UserDetailScreenDemo())),
              _DemoItem('配對列表', 'Matches List', () => _nav(context, const MatchesListScreenDemo())),
              _DemoItem('篩選條件', 'Filter', () => _nav(context, const FilterScreenDemo())),
              _DemoItem('配對成功', 'Match Success', () => _nav(context, const MatchSuccessScreenDemo())),
            ],
          ),
          _buildSection(
            context,
            title: '🍽️ 活動模組 (5個)',
            items: [
              _DemoItem('活動列表', 'Events List', () => _nav(context, const EventsListScreenDemo())),
              _DemoItem('活動詳情', 'Event Detail', () => _nav(context, const EventDetailScreenDemo())),
              _DemoItem('建立活動', 'Create Event', () => _nav(context, const CreateEventScreenDemo())),
              _DemoItem('預約確認', 'Event Confirmation', () => _nav(context, const EventConfirmationScreenDemo())),
              _DemoItem('活動評價', 'Event Rating', () => _nav(context, const EventRatingScreenDemo())),
            ],
          ),
          _buildSection(
            context,
            title: '💬 聊天模組 (3個)',
            items: [
              _DemoItem('聊天列表', 'Chat List', () => _nav(context, const ChatListScreenDemo())),
              _DemoItem('聊天詳情', 'Chat Detail', () => _nav(context, const ChatDetailScreenDemo())),
              _DemoItem('破冰話題', 'Icebreaker', () => _nav(context, const IcebreakerScreenDemo())),
            ],
          ),
          _buildSection(
            context,
            title: '⚙️ 設定模組 (6個)',
            items: [
              _DemoItem('設定頁面', 'Settings', () => _nav(context, const SettingsScreenDemo())),
              _DemoItem('編輯個人資料', 'Edit Profile', () => _nav(context, const EditProfileScreenDemo())),
              _DemoItem('隱私設定', 'Privacy Settings', () => _nav(context, const PrivacySettingsScreenDemo())),
              _DemoItem('通知設定', 'Notification Settings', () => _nav(context, const NotificationSettingsScreenDemo())),
              _DemoItem('幫助中心', 'Help Center', () => _nav(context, const HelpCenterScreenDemo())),
              _DemoItem('關於', 'About', () => _nav(context, const AboutScreenDemo())),
            ],
          ),
          _buildSection(
            context,
            title: '🔧 其他功能 (3個)',
            items: [
              _DemoItem('載入頁面', 'Loading Screen', () => _nav(context, const LoadingScreenDemo())),
              _DemoItem('錯誤頁面', 'Error Screen', () => _nav(context, const ErrorScreenDemo())),
              _DemoItem('空狀態頁面', 'Empty State', () => _nav(context, const EmptyStateScreenDemo())),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B35), Color(0xFFFF8C61)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                Text(
                  '✨ 總計 35 個介面',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Chingu UI Demo Gallery',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<_DemoItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...items.map((item) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(item.name),
                subtitle: Text(item.description),
                trailing: const Icon(Icons.chevron_right),
                onTap: item.onTap,
              ),
            )),
        const SizedBox(height: 16),
      ],
    );
  }

  void _nav(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }
}

class _DemoItem {
  final String name;
  final String description;
  final VoidCallback onTap;

  _DemoItem(this.name, this.description, this.onTap);
}
