import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
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

  // --- Notification Helper Methods ---

  String _getNotificationTitle(String type) {
    switch (type) {
      case 'match': return '配對成功!';
      case 'event': return '晚餐活動邀請';
      case 'message': return '新訊息';
      case 'system': default: return '系統通知';
    }
  }

  String _getNotificationBody(String type) {
    switch (type) {
      case 'match': return '恭喜！你和一位新朋友配對成功了。';
      case 'event': return '本週五有一場新的 6 人晚餐活動，快來報名吧！';
      case 'message': return '有人傳送了一則新訊息給你，點擊查看。';
      case 'system': default: return '這是一則來自開發者工具的測試通知。';
    }
  }

  String? _getActionType(String type) {
    switch (type) {
      case 'match': return 'match_history';
      case 'event': return 'view_event';
      case 'message': return 'open_chat';
      case 'system': default: return null;
    }
  }

  Future<void> _showLocalNotification() async {
    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final model = NotificationModel(
        id: id,
        userId: FirebaseAuth.instance.currentUser?.uid ?? 'test_user',
        type: _selectedNotificationType,
        title: _getNotificationTitle(_selectedNotificationType),
        message: _getNotificationBody(_selectedNotificationType),
        createdAt: DateTime.now(),
        actionType: _getActionType(_selectedNotificationType),
      );

      await RichNotificationService().showNotification(model);

      setState(() {
        _status = '✅ 本地通知已發送';
      });
    } catch (e) {
      setState(() {
        _status = '❌ 本地通知失敗: $e';
      });
    }
  }

  Future<void> _sendPushNotification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _status = '❌ 請先登入';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _status = '正在發送推送通知...';
    });

    try {
      await FirebaseFunctions.instance.httpsCallable('sendNotification').call({
        'recipientId': user.uid,
        'title': _getNotificationTitle(_selectedNotificationType),
        'body': _getNotificationBody(_selectedNotificationType),
        'data': {
          'type': _selectedNotificationType,
          'actionType': _getActionType(_selectedNotificationType),
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
      });

      setState(() {
        _status = '✅ 推送通知已發送 (請檢查通知欄)';
      });
    } catch (e) {
      setState(() {
        _status = '❌ 推送通知失敗: $e';
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

              const SizedBox(height: 40),
              const Divider(),
              const SizedBox(height: 20),

              // Notification Debug Section
              const Text('通知測試工具', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: DropdownButton<String>(
                  value: _selectedNotificationType,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'system', child: Text('系統通知 (System)')),
                    DropdownMenuItem(value: 'match', child: Text('配對成功 (Match)')),
                    DropdownMenuItem(value: 'event', child: Text('活動邀請 (Event)')),
                    DropdownMenuItem(value: 'message', child: Text('新訊息 (Message)')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedNotificationType = value;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _showLocalNotification,
                    icon: const Icon(Icons.notifications_active_outlined),
                    label: const Text('顯示本地通知'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _sendPushNotification,
                    icon: const Icon(Icons.cloud_upload_outlined),
                    label: const Text('發送推送通知 (Cloud)'),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              Text(
                _status,
                style: TextStyle(
                  color: _status.startsWith('❌') ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
