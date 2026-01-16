import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chingu/utils/database_seeder.dart';
import 'package:provider/provider.dart';
import 'package:chingu/providers/dinner_event_provider.dart';
import '../../services/notification_storage_service.dart';
import '../../services/rich_notification_service.dart';
import '../../models/notification_model.dart';

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

  Future<void> _sendTestNotification() async {
     setState(() {
      _isLoading = true;
      _status = '正在發送通知...';
    });

    try {
      final notificationService = NotificationStorageService();
      final richNotificationService = RichNotificationService();

      // 確保 richNotificationService 已初始化
      await richNotificationService.initialize();

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
         throw Exception('請先登入');
      }

      String title = '';
      String message = '';
      String type = _selectedNotificationType;
      String? imageUrl;
      String? actionType;
      String? actionData;

      switch (type) {
        case 'match':
          title = '新配對成功! 🎉';
          message = '你與 測試用戶 配對成功了！';
          actionType = 'open_chat';
          actionData = 'test_user_id';
          break;
        case 'event':
          title = '晚餐聚會提醒';
          message = '您報名的晚餐活動即將開始';
          actionType = 'view_event';
          actionData = 'test_event_id';
          break;
        case 'message':
          title = '測試用戶';
          message = '你好，這是一則測試訊息 👋';
          actionType = 'open_chat';
          actionData = 'test_user_id';
          break;
        case 'system':
        default:
          title = '系統通知測試';
          message = '這是一則測試通知，發送於 ${DateTime.now().toString().split('.')[0]}';
          break;
      }

      final model = NotificationModel(
        id: '', // 暫時為空，儲存後更新
        userId: currentUser.uid,
        type: type,
        title: title,
        message: message,
        imageUrl: imageUrl,
        actionType: actionType,
        actionData: actionData,
        isRead: false,
        createdAt: DateTime.now(),
      );

      // 1. 儲存到 Firestore
      final id = await notificationService.saveNotification(model);

      // 2. 更新 ID 並發送本地通知
      final sentModel = NotificationModel(
        id: id,
        userId: model.userId,
        type: model.type,
        title: model.title,
        message: model.message,
        imageUrl: model.imageUrl,
        actionType: model.actionType,
        actionData: model.actionData,
        isRead: model.isRead,
        createdAt: model.createdAt,
      );

      await richNotificationService.showNotification(sentModel);

      setState(() {
        _status = '✅ 通知發送成功！';
      });
    } catch (e) {
      setState(() {
        _status = '❌ 發送失敗: $e';
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
      body: Center(
        child: SingleChildScrollView(
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
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                const Text('通知測試工具', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: DropdownButtonFormField<String>(
                    value: _selectedNotificationType,
                    decoration: const InputDecoration(
                      labelText: '選擇通知類型',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'system', child: Text('系統通知 (System)')),
                      DropdownMenuItem(value: 'match', child: Text('配對通知 (Match)')),
                      DropdownMenuItem(value: 'event', child: Text('活動通知 (Event)')),
                      DropdownMenuItem(value: 'message', child: Text('訊息通知 (Message)')),
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
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _sendTestNotification,
                  icon: const Icon(Icons.notifications_active),
                  label: const Text('發送測試通知'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
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
