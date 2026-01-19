import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _isLoading = true;
  String? _selectedRegion;
  List<String> _selectedInterests = [];

  final NotificationService _notificationService = NotificationService();
  final FirestoreService _firestoreService = FirestoreService();

  // Available regions for subscription
  final List<String> _availableRegions = ['台北市', '台中市', '高雄市'];
  
  // Available interests
  List<String> get _availableInterests => NotificationService.interestTopics.keys.toList();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettings();
    });
  }

  Future<void> _loadSettings() async {
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid == null) return;

    try {
      final settings = await _firestoreService.getNotificationSettings(uid);
      if (mounted) {
        setState(() {
          if (settings != null) {
            _selectedRegion = settings['region'];
            _selectedInterests = List<String>.from(settings['interests'] ?? []);
          } else {
            // Default to user profile
            final user = context.read<AuthProvider>().user;
            // Check if user's city is in our supported regions
            if (user?.city != null && _availableRegions.contains(user!.city)) {
              _selectedRegion = user.city;
            } else {
              // Try partial match or leave null
              _selectedRegion = _availableRegions.firstWhere(
                (r) => user?.city.contains(r.replaceAll('市', '')) ?? false,
                orElse: () => _availableRegions.first, // Default to first or null? Let's default to Taipei if unknown
              );
            }
            _selectedInterests = user?.interests ?? [];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading settings: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSubscription() async {
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid == null) return;

    setState(() => _isLoading = true);

    try {
      await _notificationService.updateUserSubscriptions(
        uid: uid,
        newRegion: _selectedRegion,
        newInterests: _selectedInterests,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('訂閱設定已更新'),
            backgroundColor: Theme.of(context).extension<ChinguTheme>()?.success ?? Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('更新失敗: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleInterest(String interest) {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
      } else {
        _selectedInterests.add(interest);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('通知設定', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _saveSubscription,
              child: Text(
                '儲存',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : ListView(
              children: [
                _buildSectionTitle(context, '主題訂閱'),
                // Region Selector
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedRegion,
                      hint: const Text('選擇地區'),
                      isExpanded: true,
                      icon: Icon(Icons.arrow_drop_down, color: theme.colorScheme.primary),
                      dropdownColor: theme.cardColor,
                      items: _availableRegions.map((String region) {
                        return DropdownMenuItem<String>(
                          value: region,
                          child: Row(
                            children: [
                              Icon(Icons.location_city, color: theme.colorScheme.primary, size: 20),
                              const SizedBox(width: 12),
                              Text(region),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedRegion = newValue;
                        });
                      },
                    ),
                  ),
                ),
                // Interests Selector
                ExpansionTile(
                  title: Row(
                    children: [
                      Icon(Icons.interests_outlined, color: theme.colorScheme.onSurface.withOpacity(0.7)),
                      const SizedBox(width: 16),
                      Text('訂閱興趣 (${_selectedInterests.length})', style: theme.textTheme.bodyLarge),
                    ],
                  ),
                  childrenPadding: const EdgeInsets.all(16),
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableInterests.map((interest) {
                        final isSelected = _selectedInterests.contains(interest);
                        return FilterChip(
                          label: Text(interest),
                          selected: isSelected,
                          onSelected: (_) => _toggleInterest(interest),
                          selectedColor: theme.colorScheme.primary.withOpacity(0.2),
                          checkmarkColor: theme.colorScheme.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),

                const Divider(),
                _buildSectionTitle(context, '推播通知'),
                SwitchListTile(
                  title: const Text('啟用推播通知'),
                  subtitle: Text('接收應用程式的推播通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                  value: true,
                  onChanged: (v) {},
                  activeColor: theme.colorScheme.primary,
                ),
                const Divider(),
                _buildSectionTitle(context, '配對通知'),
                SwitchListTile(
                  title: const Text('新配對'),
                  subtitle: Text('當有人喜歡您時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                  value: true,
                  onChanged: (v) {},
                  activeColor: theme.colorScheme.primary,
                ),
                SwitchListTile(
                  title: const Text('配對成功'),
                  subtitle: Text('當配對成功時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                  value: true,
                  onChanged: (v) {},
                  activeColor: theme.colorScheme.primary,
                ),
                const Divider(),
                _buildSectionTitle(context, '訊息通知'),
                SwitchListTile(
                  title: const Text('新訊息'),
                  subtitle: Text('收到新訊息時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                  value: true,
                  onChanged: (v) {},
                  activeColor: theme.colorScheme.primary,
                ),
                ListTile(
                  title: const Text('顯示訊息預覽'),
                  subtitle: Text('總是顯示', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                  ),
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.notificationPreview);
                  },
                ),
                const Divider(),
                _buildSectionTitle(context, '活動通知'),
                SwitchListTile(
                  title: const Text('預約提醒'),
                  subtitle: Text('晚餐前 1 小時提醒', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                  value: true,
                  onChanged: (v) {},
                  activeColor: theme.colorScheme.primary,
                ),
                SwitchListTile(
                  title: const Text('預約變更'),
                  subtitle: Text('當預約有變更時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                  value: true,
                  onChanged: (v) {},
                  activeColor: theme.colorScheme.primary,
                ),
              ],
            ),
    );
  }
  
  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
      ),
    );
  }
}
