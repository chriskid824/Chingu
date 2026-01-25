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

  // 通知測試相關變數
  String _selectedNotificationType = 'system';
  final TextEditingController _messageController = TextEditingController(text: '這是一則測試通知');

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendTestNotification() async {
    setState(() {
      _isLoading = true;
      _status = '正在發送通知...';
    });

    try {
      final service = RichNotificationService();
      await service.initialize();

      String title;
      String? actionType;

      switch (_selectedNotificationType) {
        case 'match':
          title = '新的配對！';
          actionType = 'match_history';
          break;
        case 'event':
          title = '活動更新';
          actionType = 'view_event';
          break;
        case 'message':
          title = '新訊息';
          actionType = 'open_chat';
          break;
        case 'rating':
          title = '收到新評價';
          break;
        case 'system':
        default:
          title = '系統通知';
          break;
      }

      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: FirebaseAuth.instance.currentUser?.uid ?? 'test_user',
        type: _selectedNotificationType,
        title: title,
        message: _messageController.text,
        actionType: actionType,
        createdAt: DateTime.now(),
      );

      await service.showNotification(notification);

      setState(() {
        _status = '✅ 通知發送成功！';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('通知已發送，請查看狀態列')),
        );
      }
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
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Icon(Icons.storage_rounded, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 24),
            const Text(
              'Firebase 資料庫工具 (v2.0)',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '點擊下方按鈕將生成 6 個測試用戶和 1 個測試活動到您的 Firestore 資料庫中。',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 32),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
              ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              '通知測試工具',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _selectedNotificationType,
                      decoration: const InputDecoration(
                        labelText: '通知類型',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'system', child: Text('系統通知 (System)')),
                        DropdownMenuItem(value: 'match', child: Text('配對通知 (Match)')),
                        DropdownMenuItem(value: 'event', child: Text('活動通知 (Event)')),
                        DropdownMenuItem(value: 'message', child: Text('訊息通知 (Message)')),
                        DropdownMenuItem(value: 'rating', child: Text('評價通知 (Rating)')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedNotificationType = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        labelText: '通知內容',
                        border: OutlineInputBorder(),
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
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],
                ),
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
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}



