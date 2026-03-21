import 'package:flutter/material.dart';
import 'package:chingu/models/report_model.dart';
import 'package:chingu/services/report_block_service.dart';

/// 舉報對話框
///
/// 用於讓用戶選擇舉報原因並提交舉報
class ReportDialog extends StatefulWidget {
  final String reporterId;
  final String reportedUserId;
  final String reportedUserName;

  const ReportDialog({
    super.key,
    required this.reporterId,
    required this.reportedUserId,
    required this.reportedUserName,
  });

  /// 顯示舉報對話框
  static Future<bool?> show(
    BuildContext context, {
    required String reporterId,
    required String reportedUserId,
    required String reportedUserName,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ReportDialog(
        reporterId: reporterId,
        reportedUserId: reportedUserId,
        reportedUserName: reportedUserName,
      ),
    );
  }

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  ReportReason? _selectedReason;
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;
  bool _alsoBlock = true;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請選擇舉報原因')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final service = ReportBlockService();

      if (_alsoBlock) {
        await service.blockAndReport(
          reporterId: widget.reporterId,
          reportedUserId: widget.reportedUserId,
          reason: _selectedReason!,
          description: _descriptionController.text.isNotEmpty
              ? _descriptionController.text
              : null,
        );
      } else {
        await service.reportUser(
          reporterId: widget.reporterId,
          reportedUserId: widget.reportedUserId,
          reason: _selectedReason!,
          description: _descriptionController.text.isNotEmpty
              ? _descriptionController.text
              : null,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_alsoBlock ? '已舉報並封鎖此用戶' : '舉報已提交'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('舉報失敗: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.flag, color: Colors.orange[700]),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              '舉報用戶',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '舉報 ${widget.reportedUserName}',
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '請選擇舉報原因：',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...ReportReason.values.map((reason) => RadioListTile<ReportReason>(
              value: reason,
              groupValue: _selectedReason,
              onChanged: (value) => setState(() => _selectedReason = value),
              title: Text(reason.displayName),
              activeColor: theme.colorScheme.primary,
              contentPadding: EdgeInsets.zero,
              dense: true,
            )),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: '詳細描述（選填）',
                hintText: '請描述具體情況...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              maxLines: 3,
              maxLength: 500,
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _alsoBlock,
              onChanged: (value) => setState(() => _alsoBlock = value ?? true),
              title: const Text('同時封鎖此用戶'),
              subtitle: const Text(
                '封鎖後您將不會再看到此用戶',
                style: TextStyle(fontSize: 12),
              ),
              activeColor: theme.colorScheme.primary,
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
          child: Text(
            '取消',
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitReport,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange[700],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('提交舉報'),
        ),
      ],
    );
  }
}

/// 封鎖確認對話框
class BlockConfirmDialog extends StatelessWidget {
  final String userId;
  final String blockedUserId;
  final String blockedUserName;

  const BlockConfirmDialog({
    super.key,
    required this.userId,
    required this.blockedUserId,
    required this.blockedUserName,
  });

  /// 顯示封鎖確認對話框
  static Future<bool?> show(
    BuildContext context, {
    required String userId,
    required String blockedUserId,
    required String blockedUserName,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => BlockConfirmDialog(
        userId: userId,
        blockedUserId: blockedUserId,
        blockedUserName: blockedUserName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.block, color: Colors.red[700]),
          const SizedBox(width: 8),
          const Text(
            '封鎖用戶',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('確定要封鎖 $blockedUserName？'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '封鎖後：',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4),
                Text('• 對方不會出現在您的配對列表中'),
                Text('• 你們之間無法發送訊息'),
                Text('• 您可以在設定中解除封鎖'),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            '取消',
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            try {
              final service = ReportBlockService();
              await service.blockUser(userId, blockedUserId);
              if (context.mounted) {
                Navigator.of(context).pop(true);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('已封鎖 $blockedUserName'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('封鎖失敗: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[700],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('確定封鎖'),
        ),
      ],
    );
  }
}
