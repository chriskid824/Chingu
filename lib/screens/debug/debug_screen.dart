import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chingu/utils/database_seeder.dart';
import 'package:provider/provider.dart';
import 'package:chingu/providers/dinner_event_provider.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  bool _isLoading = false;
  String _status = '';

  Future<void> _runFullTestScenarios() async {
    setState(() {
      _isLoading = true;
      _status = '🧪 正在生成完整測試情境資料...';
    });

    try {
      final seeder = DatabaseSeeder();
      await seeder.seedTestScenariosForUser();

      // 刷新 Provider
      if (mounted) {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId != null) {
          await context.read<DinnerEventProvider>().fetchMyEvents(userId);
        }
      }

      setState(() {
        _status = '✅ 完整測試資料生成成功！';
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('🎉 測試資料已生成'),
            content: const Text(
              '已成功寫入 Firestore：\n\n'
              '• 5 個假用戶（Alex, Sophie, Kevin, Tina, Ryan）\n'
              '• 2 個已過期活動（可在 Events Tab 看到）\n'
              '• 2 個未來活動（可測試報名）\n'
              '• 4 個群組（pending/info/location/completed）\n'
              '• 1 個群組聊天室（聊天 Tab 可看到）\n'
              '• 1 個 1v1 聊天室（Mutual Match）\n'
              '• 1 筆待評價（Events → 回饋 可測試）\n'
              '• 免費額度 = 2 次\n\n'
              '請回到首頁並刷新。',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('知道了'),
              ),
            ],
          ),
        );
      }
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.science_rounded, size: 64, color: Colors.teal),
            const SizedBox(height: 20),
            const Text('測試資料工具', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              FirebaseAuth.instance.currentUser?.email ?? '未登入',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 32),

            // 狀態資訊
            if (_status.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _status.startsWith('❌') ? Colors.red.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _status.startsWith('❌') ? Colors.red.shade700 : Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            if (_isLoading) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
            ],

            // 唯一按鈕：生成完整測試資料
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _runFullTestScenarios,
                icon: const Icon(Icons.science_rounded, size: 24),
                label: const Text('生成完整測試資料', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '活動 · 群組 · 聊天室 · 評價 · 訂閱',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
