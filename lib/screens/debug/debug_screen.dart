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

  // Notification Debug State
  String _notificationType = 'system';
  final TextEditingController _titleController = TextEditingController(text: '測試通知');
  final TextEditingController _messageController = TextEditingController(text: '這是一則測試通知內容，用於驗證通知功能是否正常運作。');
  bool _enableDelay = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

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
    if (_enableDelay) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('將在 5 秒後發送通知，請切換到背景...')),
      );
      await Future.delayed(const Duration(seconds: 5));
    }

    try {
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: FirebaseAuth.instance.currentUser?.uid ?? 'test_user',
        type: _notificationType,
        title: _titleController.text,
        message: _messageController.text,
        createdAt: DateTime.now(),
        // 根據類型設置一些預設的 action
        actionType: _getActionTypeFor(_notificationType),
        actionData: _getActionDataFor(_notificationType),
      );

      await RichNotificationService().showNotification(notification);

      if (mounted && !_enableDelay) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('通知已發送')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('發送失敗: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String? _getActionTypeFor(String type) {
    switch (type) {
      case 'match':
        return 'match_history'; // or open_chat
      case 'event':
        return 'view_event';
      case 'message':
        return 'open_chat';
      default:
        return null;
    }
  }

  String? _getActionDataFor(String type) {
    // Return dummy data for testing navigation
    switch (type) {
      case 'event':
        return 'test_event_id';
      case 'message':
        return 'test_user_id';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('開發者工具')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
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
              ],
              const SizedBox(height: 24),
              Text(
                _status,
                style: TextStyle(
                  color: _status.startsWith('❌') ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const Divider(height: 48, thickness: 2),

              // Notification Debug Section
              Icon(Icons.notifications_active_rounded, size: 48, color: Colors.orange),
              const SizedBox(height: 16),
              const Text('通知測試工具', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _notificationType,
                      decoration: const InputDecoration(labelText: '通知類型'),
                      items: const [
                        DropdownMenuItem(value: 'system', child: Text('系統通知 (System)')),
                        DropdownMenuItem(value: 'match', child: Text('配對成功 (Match)')),
                        DropdownMenuItem(value: 'event', child: Text('活動提醒 (Event)')),
                        DropdownMenuItem(value: 'message', child: Text('新訊息 (Message)')),
                        DropdownMenuItem(value: 'rating', child: Text('評價邀請 (Rating)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _notificationType = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: '標題'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(labelText: '內容'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('延遲 5 秒發送'),
                      subtitle: const Text('開啟後按發送，然後將 App 切到背景測試'),
                      value: _enableDelay,
                      onChanged: (val) => setState(() => _enableDelay = val),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _sendTestNotification,
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('發送測試通知'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
