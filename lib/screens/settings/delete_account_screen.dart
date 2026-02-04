import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../core/routes/app_router.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  // Confirmation states
  bool _confirmIrreversible = false;
  bool _confirmDataLoss = false;

  // Reason selection
  String? _selectedReason;
  final List<String> _reasons = [
    '找到對象了',
    '覺得不實用',
    '隱私考量',
    '遇到技術問題',
    '其他原因',
  ];

  Future<void> _handleDeleteAccount() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.deleteAccount();

      if (mounted) {
        // Show success message and navigate to splash/login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('帳號已成功刪除')),
        );
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.splash, // Or login, but splash usually redirects appropriately
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Check for specific error exception
        if (e is AuthRequiresRecentLoginException) {
           showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('認證過期'),
              content: const Text('為了您的帳號安全，刪除帳號需要您重新登入。請登出後再次登入，然後嘗試刪除帳號。'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _handleLogout();
                  },
                  child: const Text('前往登出'),
                ),
              ],
            ),
          );
        } else {
          // e could be a String from _handleAuthException or Exception object
          final errorMessage = e.toString().replaceAll('Exception: ', '');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('刪除失敗: $errorMessage')),
          );
        }
      }
    }
  }

  Future<void> _handleLogout() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.login,
          (route) => false,
        );
      }
    } catch (e) {
      // Handle logout error
    }
  }

  void _requestDataExport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('數據導出功能尚未開放，敬請期待。')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDeleteEnabled = _confirmIrreversible && _confirmDataLoss;

    return Scaffold(
      appBar: AppBar(
        title: const Text('刪除帳號'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Warning Header
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        size: 48,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '您確定要刪除帳號嗎？',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '刪除帳號是永久性的操作，無法復原。您的個人資料、配對紀錄、聊天訊息以及所有活動紀錄都將被永久刪除。',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Data Export
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    '在刪除之前',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '如果您想保留您的數據副本，請在刪除帳號前申請導出。',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _requestDataExport,
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('申請數據導出'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Reason Selection
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    '為什麼要離開？(選填)',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedReason,
                    hint: const Text('請選擇原因'),
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: _reasons.map((reason) {
                      return DropdownMenuItem(
                        value: reason,
                        child: Text(reason),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedReason = value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // Confirmation Checkboxes
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    '確認刪除',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: _confirmIrreversible,
                    onChanged: (value) {
                      setState(() {
                        _confirmIrreversible = value ?? false;
                      });
                    },
                    title: const Text('我了解此操作無法復原'),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    value: _confirmDataLoss,
                    onChanged: (value) {
                      setState(() {
                        _confirmDataLoss = value ?? false;
                      });
                    },
                    title: const Text('我了解所有數據將被永久刪除'),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 32),

                  // Delete Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isDeleteEnabled
                          ? () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('最後確認'),
                                  content: const Text('這真的是最後一步了。您確定要立即刪除帳號嗎？'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text('取消'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        _handleDeleteAccount();
                                      },
                                      child: Text(
                                        '確認刪除',
                                        style: TextStyle(color: theme.colorScheme.error),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        '永久刪除帳號',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
