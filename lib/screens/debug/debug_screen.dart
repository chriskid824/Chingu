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
  String _selectedScenarioKey = 'System Alert';

  final Map<String, NotificationModel> _testScenarios = {
    'System Alert': NotificationModel(
      id: 'debug_system',
      userId: 'current_user',
      type: 'system',
      title: '系統通知',
      message: '這是一條系統測試通知。',
      createdAt: DateTime.now(),
    ),
    'New Match': NotificationModel(
      id: 'debug_match',
      userId: 'current_user',
      type: 'match',
      title: '配對成功！',
      message: '你與 Alice 配對成功了！',
      actionType: 'match_history',
      createdAt: DateTime.now(),
    ),
    'New Message': NotificationModel(
      id: 'debug_message',
      userId: 'current_user',
      type: 'message',
      title: '新訊息',
      message: 'Bob 傳送了一則訊息給你。',
      actionType: 'open_chat',
      actionData: 'dummy_user_id',
      createdAt: DateTime.now(),
    ),
    'Event Reminder': NotificationModel(
      id: 'debug_event',
      userId: 'current_user',
      type: 'event',
      title: '活動提醒',
      message: '晚餐聚會即將在 1 小時後開始。',
      actionType: 'view_event',
      actionData: 'dummy_event_id',
      createdAt: DateTime.now(),
    ),
  };

  Future<void> _sendTestNotification() async {
    final scenario = _testScenarios[_selectedScenarioKey];
    if (scenario == null) return;

    final notification = NotificationModel(
      id: 'debug_${DateTime.now().millisecondsSinceEpoch}',
      userId: FirebaseAuth.instance.currentUser?.uid ?? 'anonymous',
      type: scenario.type,
      title: scenario.title,
      message: scenario.message,
      actionType: scenario.actionType,
      actionData: scenario.actionData,
      createdAt: DateTime.now(),
    );

    await RichNotificationService().showNotification(notification);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已發送通知: ${notification.title}')),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('開發者工具')),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
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
                    onPressed: _generateMatchTestData,
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
                    onPressed: _clearData,
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('清除所有數據'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
                const Divider(height: 48),
                const Text('通知測試工具', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: DropdownButton<String>(
                    value: _selectedScenarioKey,
                    isExpanded: true,
                    items: _testScenarios.keys.map((String key) {
                      return DropdownMenuItem<String>(
                        value: key,
                        child: Text(key),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedScenarioKey = newValue!;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _sendTestNotification,
                  icon: const Icon(Icons.notifications_active_rounded),
                  label: const Text('發送測試通知'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
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
      ),
    );
  }
}



