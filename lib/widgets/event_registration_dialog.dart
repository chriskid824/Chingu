import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/dinner_event_model.dart';
import '../services/dinner_event_service.dart';
import '../providers/auth_provider.dart';
import '../core/theme/app_theme.dart';
import '../widgets/gradient_button.dart';

class EventRegistrationDialog extends StatefulWidget {
  final DinnerEventModel event;

  const EventRegistrationDialog({
    Key? key,
    required this.event,
  }) : super(key: key);

  @override
  State<EventRegistrationDialog> createState() => _EventRegistrationDialogState();
}

class _EventRegistrationDialogState extends State<EventRegistrationDialog> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    final isFull = widget.event.participantIds.length >= widget.event.maxParticipants;
    final waitlistCount = widget.event.waitlistIds.length;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isFull ? '加入等候清單' : '確認報名',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              Icons.calendar_today_rounded,
              DateFormat('yyyy/MM/dd HH:mm').format(widget.event.dateTime),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              context,
              Icons.location_on_rounded,
              '${widget.event.city} ${widget.event.district}',
            ),
            const SizedBox(height: 8),
             _buildInfoRow(
              context,
              Icons.people_alt_rounded,
              isFull
                ? '目前滿員 (已有 $waitlistCount 人排隊)'
                : '剩餘 ${widget.event.maxParticipants - widget.event.participantIds.length} 個名額',
              color: isFull ? theme.colorScheme.error : chinguTheme?.success,
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: theme.colorScheme.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GradientButton(
                    text: isFull ? '加入候補' : '確認參加',
                    isLoading: _isLoading,
                    onPressed: _handleRegistration,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text, {Color? color}) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? theme.colorScheme.onSurface.withOpacity(0.6)),
        const SizedBox(width: 12),
        Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: color ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Future<void> _handleRegistration() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.userModel?.uid;

      if (userId == null) {
        throw Exception('請先登入');
      }

      await DinnerEventService().registerForEvent(widget.event.id, userId);

      if (mounted) {
        Navigator.of(context).pop(true); // Return true on success
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(widget.event.participantIds.length >= widget.event.maxParticipants
               ? '已加入等候清單'
               : '報名成功！')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
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
}
