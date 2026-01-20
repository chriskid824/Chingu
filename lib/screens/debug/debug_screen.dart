import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chingu/utils/database_seeder.dart';
import 'package:provider/provider.dart';
import 'package:chingu/providers/dinner_event_provider.dart';
import 'package:chingu/services/rich_notification_service.dart';
import 'package:chingu/models/notification_model.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  bool _isLoading = false;
  String _status = '';
  String _selectedNotificationType = 'system';

  final Map<String, String> _notificationTypes = {
    'system': '系統通知',
    'match': '配對成功',
    'message': '新訊息',
    'event': '活動邀請',
    'rating': '評價提醒',
  };

  Future<void> _runSeeder() async {
    setState(() {
      _isLoading = true;
      _status = '正在準備環境...';
    });

    try {
      // 確保已登入（匿名登入）
      if (FirebaseAuth.instance.currentUser == null) {
        _status = '正在進行匿名登入...';
        await FirebaseAuth.instance.signInAnonymously();
      }

      setState(() {
        _status = '正在寫入測試數據...';
      });

      final seeder = DatabaseSeeder();
      await seeder.seedData();
      setState(() {
        _status = '✅ 數據生成成功！請重新整理配對頁面。';
      });
    } catch (e) {
      setState(() {
        _status = '❌ 錯誤: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearData() async {
    setState(() {
      _isLoading = true;
      _status = '正在清除數據...';
    });

    try {
      final seeder = DatabaseSeeder();
      await seeder.clearAllData();
      
      // 刷新 Provider
      if (mounted) {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId != null) {
          await context.read<DinnerEventProvider>().fetchMyEvents(userId);
        }
      }

      setState(() {
        _status = '✅ 數據清除成功！';
      });
    } catch (e) {
      setState(() {
        _status = '❌ 清除失敗: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _generateMatchTestData() async {
    setState(() {
      _isLoading = true;
      _status = '正在生成配對測試數據...';
    });

    try {
      final seeder = DatabaseSeeder();
      await seeder.seedMutualLikes();
      
      setState(() {
        _status = '✅ 配對測試數據生成成功！請到配對頁面測試。';
      });
    } catch (e) {
      setState(() {
        _status = '❌ 生成失敗: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendTestNotification() async {
    setState(() {
      _status = '正在發送測試通知...';
    });

    try {
      final notification = _createTestNotification(_selectedNotificationType);
      await RichNotificationService().showNotification(notification);

      setState(() {
        _status = '✅ 通知發送成功！請查看通知欄。';
      });
    } catch (e) {
      setState(() {
        _status = '❌ 通知發送失敗: $e';
      });
    }
  }

  NotificationModel _createTestNotification(String type) {
    final now = DateTime.now();
    final id = now.millisecondsSinceEpoch.toString();
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'test_user';

    String title = '測試通知';
    String message = '這是一則測試通知';
    String? imageUrl;
    String? actionType;
    String? actionData;

    switch (type) {
      case 'match':
        title = '配對成功！';
        message = '你和 Jessica 配對成功了！快來打個招呼吧 👋';
        imageUrl = 'https://randomuser.me/api/portraits/women/44.jpg'; // 測試圖片
        actionType = 'open_chat';
        actionData = 'test_chat_id';
        break;
      case 'message':
        title = '新訊息';
        message = 'Alex: 今晚要一起吃晚餐嗎？';
        imageUrl = 'https://randomuser.me/api/portraits/men/32.jpg';
        actionType = 'open_chat';
        actionData = 'test_chat_id';
        break;
      case 'event':
        title = '活動邀請';
        message = '你被邀請參加「週五韓式烤肉夜」！';
        imageUrl = 'https://images.unsplash.com/photo-1599487488170-d11ec9c172f0?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60';
        actionType = 'view_event';
        actionData = 'test_event_id';
        break;
      case 'rating':
        title = '評價提醒';
        message = '昨天的晚餐如何？請給予評價！';
        actionType = 'navigate';
        actionData = '/feedback'; // 假設的路徑
        break;
      case 'system':
      default:
        title = '系統通知';
        message = '歡迎使用 Chingu 開發者測試工具。';
        break;
    }

    return NotificationModel(
      id: id,
      userId: userId,
      type: type,
      title: title,
      message: message,
      imageUrl: imageUrl,
      actionType: actionType,
      actionData: actionData,
      isRead: false,
      createdAt: now,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('開發者工具')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.storage_rounded, size: 64, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 24),
              const Center(
                child: Text('Firebase 資料庫工具 (v2.0)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              const Text(
                '點擊下方按鈕將生成 6 個測試用戶和 1 個測試活動到您的 Firestore 資料庫中。',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                ElevatedButton.icon(
                  onPressed: _runSeeder,
                  icon: const Icon(Icons.add_to_photos_rounded),
                  label: const Text('生成測試數據 (Seeder)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _generateMatchTestData,
                  icon: const Icon(Icons.favorite_rounded),
                  label: const Text('生成配對測試數據'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.pink,
                    side: const BorderSide(color: Colors.pink),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _clearData,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('清除所有數據'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),

                const Divider(height: 48),
                const Center(
                  child: Text('通知測試工具', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _selectedNotificationType,
                  decoration: const InputDecoration(
                    labelText: '通知類型',
                    border: OutlineInputBorder(),
                  ),
                  items: _notificationTypes.entries.map((entry) {
                    return DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedNotificationType = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _sendTestNotification,
                  icon: const Icon(Icons.notifications_active_rounded),
                  label: const Text('發送測試通知'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],

              const SizedBox(height: 24),
              Center(
                child: Text(
                  _status,
                  style: TextStyle(
                    color: _status.startsWith('❌') ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
