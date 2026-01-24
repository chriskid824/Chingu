import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/gradient_button.dart';

enum RegistrationAction {
  join,
  joinWaitlist,
  leave,
  leaveWaitlist,
}

class EventRegistrationDialog extends StatelessWidget {
  final RegistrationAction action;
  final VoidCallback onConfirm;
  final bool isProcessing;

  const EventRegistrationDialog({
    super.key,
    required this.action,
    required this.onConfirm,
    this.isProcessing = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(context),
            const SizedBox(height: 16),
            Text(
              _getTitle(),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _getMessage(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (isProcessing)
              const CircularProgressIndicator()
            else
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        '取消',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GradientButton(
                      text: _getButtonText(),
                      onPressed: onConfirm,
                      gradient: _getGradient(context),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    IconData icon;
    Color color;

    switch (action) {
      case RegistrationAction.join:
        icon = Icons.check_circle_rounded;
        color = Colors.green;
        break;
      case RegistrationAction.joinWaitlist:
        icon = Icons.hourglass_top_rounded;
        color = Colors.orange;
        break;
      case RegistrationAction.leave:
      case RegistrationAction.leaveWaitlist:
        icon = Icons.warning_rounded;
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 32,
        color: color,
      ),
    );
  }

  String _getTitle() {
    switch (action) {
      case RegistrationAction.join:
        return '確認報名';
      case RegistrationAction.joinWaitlist:
        return '加入候補';
      case RegistrationAction.leave:
        return '取消報名';
      case RegistrationAction.leaveWaitlist:
        return '取消候補';
    }
  }

  String _getMessage() {
    switch (action) {
      case RegistrationAction.join:
        return '報名後請準時出席，爽約將會影響您的信用評分。';
      case RegistrationAction.joinWaitlist:
        return '目前活動人數已滿。加入候補名單後，若有名額釋出將自動為您候補。';
      case RegistrationAction.leave:
        return '確定要取消報名嗎？如果在活動前 24 小時內取消，可能會扣除信用點數。';
      case RegistrationAction.leaveWaitlist:
        return '確定要退出候補名單嗎？';
    }
  }

  String _getButtonText() {
    switch (action) {
      case RegistrationAction.join:
        return '確認參加';
      case RegistrationAction.joinWaitlist:
        return '加入候補';
      case RegistrationAction.leave:
        return '確認取消';
      case RegistrationAction.leaveWaitlist:
        return '退出候補';
    }
  }

  Gradient? _getGradient(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    switch (action) {
      case RegistrationAction.join:
      case RegistrationAction.joinWaitlist:
        return chinguTheme?.primaryGradient;
      case RegistrationAction.leave:
      case RegistrationAction.leaveWaitlist:
        return const LinearGradient(
          colors: [Color(0xFFFF512F), Color(0xFFDD2476)], // Red gradient
        );
    }
  }
}
