import 'package:flutter/material.dart';
import '../services/broadcast_service.dart';
import '../core/theme/app_colors_minimal.dart';

/// Admin screen for sending broadcast notifications
/// This should only be accessible to admin users
class AdminBroadcastScreen extends StatefulWidget {
  const AdminBroadcastScreen({super.key});

  @override
  State<AdminBroadcastScreen> createState() => _AdminBroadcastScreenState();
}

class _AdminBroadcastScreenState extends State<AdminBroadcastScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _citiesController = TextEditingController();
  final _broadcastService = BroadcastService();

  String _targetType = 'all'; // 'all', 'cities', 'users'
  bool _isLoading = false;
  BroadcastResult? _lastResult;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _imageUrlController.dispose();
    _citiesController.dispose();
    super.dispose();
  }

  Future<void> _sendBroadcast() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _lastResult = null;
    });

    try {
      BroadcastResult result;

      if (_targetType == 'all') {
        result = await _broadcastService.sendToAllUsers(
          title: _titleController.text.trim(),
          body: _bodyController.text.trim(),
          imageUrl: _imageUrlController.text.trim().isNotEmpty 
              ? _imageUrlController.text.trim() 
              : null,
        );
      } else if (_targetType == 'cities') {
        final cities = _citiesController.text
            .split(',')
            .map((c) => c.trim().toLowerCase())
            .where((c) => c.isNotEmpty)
            .toList();

        result = await _broadcastService.sendToCities(
          title: _titleController.text.trim(),
          body: _bodyController.text.trim(),
          cities: cities,
          imageUrl: _imageUrlController.text.trim().isNotEmpty 
              ? _imageUrlController.text.trim() 
              : null,
        );
      } else {
        throw UnimplementedError('User targeting not yet implemented');
      }

      setState(() {
        _lastResult = result;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ 成功發送 ${result.successCount} 則通知'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('系統廣播通知'),
        backgroundColor: AppColorsMinimal.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Target type selector
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '發送對象',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      RadioListTile<String>(
                        title: const Text('所有用戶'),
                        value: 'all',
                        groupValue: _targetType,
                        onChanged: (value) => setState(() => _targetType = value!),
                      ),
                      RadioListTile<String>(
                        title: const Text('指定城市'),
                        value: 'cities',
                        groupValue: _targetType,
                        onChanged: (value) => setState(() => _targetType = value!),
                      ),
                      RadioListTile<String>(
                        title: const Text('指定用戶 (暫未實現)'),
                        value: 'users',
                        groupValue: _targetType,
                        onChanged: null, // Disabled for now
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Cities input (only show if cities selected)
              if (_targetType == 'cities') ...[
                TextFormField(
                  controller: _citiesController,
                  decoration: const InputDecoration(
                    labelText: '城市列表',
                    hintText: '例如: taipei, taichung, kaohsiung',
                    helperText: '用逗號分隔多個城市',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (_targetType == 'cities' && (value == null || value.trim().isEmpty)) {
                      return '請輸入至少一個城市';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '通知標題 *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '請輸入標題';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Body
              TextFormField(
                controller: _bodyController,
                decoration: const InputDecoration(
                  labelText: '通知內容 *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '請輸入內容';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Image URL (optional)
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: '圖片網址 (選填)',
                  hintText: 'https://example.com/image.jpg',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),

              // Send button
              ElevatedButton(
                onPressed: _isLoading ? null : _sendBroadcast,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorsMinimal.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        '發送通知',
                        style: TextStyle(fontSize: 16),
                      ),
              ),

              // Last result
              if (_lastResult != null) ...[
                const SizedBox(height: 24),
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '發送結果',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('成功: ${_lastResult!.successCount}'),
                        Text('失敗: ${_lastResult!.failureCount}'),
                        Text('總計: ${_lastResult!.totalTargets}'),
                        Text(
                          '成功率: ${_lastResult!.successRate.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: _lastResult!.successRate > 90 
                                ? Colors.green 
                                : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Help text
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '💡 提示:\n'
                  '• 通知會立即發送給所有符合條件的用戶\n'
                  '• 請確保內容準確無誤\n'
                  '• 所有廣播都會被記錄在系統中',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
