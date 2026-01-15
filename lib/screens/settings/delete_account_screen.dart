import 'package:flutter/material.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/services/auth_service.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final PageController _pageController = PageController();
  final AuthService _authService = AuthService();
  final TextEditingController _confirmController = TextEditingController();

  int _currentPage = 0;
  bool _isExportSelected = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _pageController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _prevPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _handleDelete() async {
    if (_confirmController.text != 'DELETE') return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isExportSelected) {
        // Mock export logic
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('您的資料匯出請求已收到，將發送至您的電子郵件。')),
          );
        }
      }

      await _authService.deleteAccount();

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.login,
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('無法刪除帳號'),
            content: Text(e.toString().replaceAll('Exception: ', '')),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('確定'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildStepIndicator(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isActive = index <= _currentPage;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? theme.colorScheme.error : theme.colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildScrollableContent({required Widget child}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWarningStep(ThemeData theme) {
    return _buildScrollableContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Icon(Icons.warning_amber_rounded, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: 24),
          Text(
            '刪除帳號將無法復原',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '刪除帳號後，您將會永久失去以下資料：',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          _buildBulletPoint(theme, '您的個人資料和照片'),
          _buildBulletPoint(theme, '所有的配對紀錄和聊天訊息'),
          _buildBulletPoint(theme, '活動報名紀錄'),
          _buildBulletPoint(theme, '個人偏好設定'),
          const Spacer(),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _nextPage,
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('繼續'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 6, color: theme.colorScheme.onSurface),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildExportStep(ThemeData theme) {
    return _buildScrollableContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Icon(Icons.download_rounded, size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            '保留您的資料？',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '在刪除帳號之前，您可以選擇匯出您的個人資料。我們將會把資料整理後寄送至您的電子郵件信箱。',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 32),
          CheckboxListTile(
            value: _isExportSelected,
            onChanged: (value) {
              setState(() {
                _isExportSelected = value ?? false;
              });
            },
            title: const Text('是的，我想匯出我的資料'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: theme.colorScheme.primary,
          ),
          const Spacer(),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _nextPage,
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('下一步'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                setState(() {
                  _isExportSelected = false;
                });
                _nextPage();
              },
              child: const Text('不，我不想要保留資料'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmStep(ThemeData theme) {
    return _buildScrollableContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Icon(Icons.delete_forever_rounded, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: 24),
          Text(
            '最終確認',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '這是最後一步了。請在下方輸入 "DELETE" 以確認刪除您的帳號。此操作無法復原。',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _confirmController,
            decoration: InputDecoration(
              hintText: 'DELETE',
              border: const OutlineInputBorder(),
              errorText: _confirmController.text.isNotEmpty &&
                        _confirmController.text != 'DELETE'
                  ? '請輸入 DELETE'
                  : null,
            ),
            onChanged: (value) => setState(() {}),
          ),
          const Spacer(),
          const SizedBox(height: 24),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _confirmController.text == 'DELETE' ? _handleDelete : null,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  disabledBackgroundColor: theme.colorScheme.error.withOpacity(0.3),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('確認刪除帳號'),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: _currentPage == 0,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _prevPage();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('刪除帳號'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (_currentPage > 0) {
                _prevPage();
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: _buildStepIndicator(theme),
          ),
        ),
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
            });
          },
          children: [
            _buildWarningStep(theme),
            _buildExportStep(theme),
            _buildConfirmStep(theme),
          ],
        ),
      ),
    );
  }
}
