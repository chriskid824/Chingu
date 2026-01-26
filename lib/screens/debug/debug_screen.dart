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
  final List<String> _notificationTypes = ['system', 'match', 'event', 'message'];

  Future<void> _runSeeder() async {
    setState(() {
      _isLoading = true;
      _status = '正在準備環境...';
    });

    try {
      // 確保已登入（匿名登入）
      if (FirebaseAuth.instance.currentUser == null) {
        if (mounted) {
          setState(() {
            _status = '正在進行匿名登入...';
          });
        }
        await FirebaseAuth.instance.signInAnonymously();
      }

      if (mounted) {
        setState(() {
          _status = '正在寫入測試數據...';
        });
      }

      final seeder = DatabaseSeeder();
      await seeder.seedData();

      if (mounted) {
        setState(() {
          _status = '✅ 數據生成成功！請重新整理配對頁面。';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = '❌ 錯誤: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

      if (mounted) {
        setState(() {
          _status = '✅ 數據清除成功！';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = '❌ 清除失敗: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
      
      if (mounted) {
        setState(() {
          _status = '✅ 配對測試數據生成成功！請到配對頁面測試。';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = '❌ 生成失敗: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendTestNotification() async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'test_user';
    String title = '測試通知';
    String message = '這是一條測試通知內容';
    String? actionType;
    String? actionData;

    switch (_selectedNotificationType) {
      case 'match':
        title = '配對成功！';
        message = '恭喜！你與某人配對成功，快去看看吧！';
        actionType = 'match_history';
        break;
      case 'event':
        title = '晚餐活動更新';
        message = '你的晚餐活動有新的動態，點擊查看詳情。';
        actionType = 'view_event';
        // 這裡可以放一個測試的 eventId
        actionData = 'test_event_id';
        break;
      case 'message':
        title = '新訊息';
        message = '你收到了一條新訊息。';
        actionType = 'open_chat';
        // 這裡可以放一個測試的 chatRoomId 或 userId
        actionData = 'test_chat_id';
        break;
      case 'system':
      default:
        title = '系統通知';
        message = '這是系統發送的測試通知。';
        actionType = 'default';
        break;
    }

    final notification = NotificationModel(
      id: 'test_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      type: _selectedNotificationType,
      title: title,
      message: message,
      actionType: actionType,
      actionData: actionData,
      createdAt: DateTime.now(),
      isRead: false,
    );

    try {
      await RichNotificationService().showNotification(notification);
      if (mounted) {
        setState(() {
          _status = '✅ 測試通知已發送 ($_selectedNotificationType)';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = '❌ 發送通知失敗: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('開發者工具')),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
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
                ],
                const SizedBox(height: 32),
                const Divider(indent: 32, endIndent: 32),
                const SizedBox(height: 16),
                const Text('推送通知測試', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('通知類型: '),
                      const SizedBox(width: 16),
                      DropdownButton<String>(
                        value: _selectedNotificationType,
                        items: _notificationTypes.map((String type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedNotificationType = newValue;
                            });
                          }
                        },
                      ),
                    ],
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
                  textAlign: TextAlign.center,
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
