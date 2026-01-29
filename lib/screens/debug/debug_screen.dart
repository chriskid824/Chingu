import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chingu/utils/database_seeder.dart';
import 'package:provider/provider.dart';
import 'package:chingu/providers/dinner_event_provider.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:chingu/services/rich_notification_service.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  bool _isLoading = false;
  String _status = '';

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

  void _showNotificationDebugDialog() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('發送測試通知'),
        children: [
          _buildNotificationOption(
            title: '配對通知',
            icon: Icons.favorite,
            color: Colors.pink,
            onTap: () => _sendTestNotification('match'),
          ),
          _buildNotificationOption(
            title: '活動提醒',
            icon: Icons.event,
            color: Colors.orange,
            onTap: () => _sendTestNotification('event'),
          ),
          _buildNotificationOption(
            title: '新訊息',
            icon: Icons.message,
            color: Colors.blue,
            onTap: () => _sendTestNotification('message'),
          ),
          _buildNotificationOption(
            title: '系統通知',
            icon: Icons.notifications,
            color: Colors.grey,
            onTap: () => _sendTestNotification('system'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationOption({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SimpleDialogOption(
      onPressed: () {
        Navigator.pop(context);
        onTap();
      },
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Text(title),
        ],
      ),
    );
  }

  Future<void> _sendTestNotification(String type) async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'test_user';
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    NotificationModel? notification;

    switch (type) {
      case 'match':
        notification = NotificationModel(
          id: id,
          userId: userId,
          type: 'match',
          title: 'New Match! 🎉',
          message: 'You matched with a new user. Tap to say hi!',
          actionType: 'match_history', // or open_chat
          createdAt: DateTime.now(),
        );
        break;
      case 'event':
        notification = NotificationModel(
          id: id,
          userId: userId,
          type: 'event',
          title: 'Dinner Reminder 🍽️',
          message: 'Your dinner event starts in 1 hour at X Restaurant.',
          actionType: 'view_event',
          actionData: 'test_event_id',
          createdAt: DateTime.now(),
        );
        break;
      case 'message':
        notification = NotificationModel(
          id: id,
          userId: userId,
          type: 'message',
          title: 'New Message 💬',
          message: 'Alice: Hey, are you going to the dinner tonight?',
          actionType: 'open_chat',
          actionData: 'test_chat_id',
          createdAt: DateTime.now(),
        );
        break;
      case 'system':
      default:
        notification = NotificationModel(
          id: id,
          userId: userId,
          type: 'system',
          title: 'System Update 🔔',
          message: 'We have updated our terms of service.',
          createdAt: DateTime.now(),
        );
        break;
    }

    try {
      await RichNotificationService().showNotification(notification);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已發送 $type 測試通知')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('發送失敗: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('開發者工具')),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.storage_rounded, size: 64, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 24),
              const Text('Firebase 資料庫工具 (v2.0)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  '點擊下方按鈕將生成 6 個測試用戶和 1 個測試活動到您的 Firestore 資料庫中。',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                const CircularProgressIndicator()
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
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _showNotificationDebugDialog,
                  icon: const Icon(Icons.notifications_active_rounded),
                  label: const Text('發送測試通知'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.deepPurple,
                    side: const BorderSide(color: Colors.deepPurple),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Text(
                _status,
                style: TextStyle(
                  color: _status.startsWith('❌') ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
