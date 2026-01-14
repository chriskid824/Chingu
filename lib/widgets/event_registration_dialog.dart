import 'package:flutter/material.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/widgets/gradient_button.dart';
import 'package:chingu/core/theme/app_theme.dart';

class EventRegistrationDialog extends StatefulWidget {
  final DinnerEventModel event;
  final String userId;
  final DinnerEventService eventService;

  const EventRegistrationDialog({
    Key? key,
    required this.event,
    required this.userId,
    required this.eventService,
  }) : super(key: key);

  static Future<bool?> show(
    BuildContext context, {
    required DinnerEventModel event,
    required String userId,
    required DinnerEventService eventService,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => EventRegistrationDialog(
        event: event,
        userId: userId,
        eventService: eventService,
      ),
    );
  }

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
    final status = widget.event.getUserRegistrationStatus(widget.userId);
    final isFull = widget.event.isFull;

    String title;
    String message;
    String buttonText;
    bool isDestructive = false;

    switch (status) {
      case EventRegistrationStatus.registered:
        title = '取消報名';
        message = '您確定要取消報名此活動嗎？\n活動前 24 小時內不可取消。';
        buttonText = '確認取消';
        isDestructive = true;
        break;
      case EventRegistrationStatus.waitlist:
        title = '取消候補';
        message = '您確定要退出候補名單嗎？';
        buttonText = '退出候補';
        isDestructive = true;
        break;
      case EventRegistrationStatus.none:
      default:
        if (isFull) {
          title = '加入候補名單';
          message = '目前活動名額已滿，您要加入候補名單嗎？\n若有名額釋出，將依序遞補。';
          buttonText = '加入候補';
        } else {
          title = '確認報名';
          message = '您確定要報名此活動嗎？\n活動時間：${_formatDate(widget.event.dateTime)}';
          buttonText = '確認報名';
        }
        break;
    }

    return Dialog(
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
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
                    Icon(
                      Icons.error_outline,
                      size: 20,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Column(
                children: [
                  GradientButton(
                    text: buttonText,
                    onPressed: () => _handleAction(status),
                    gradient: isDestructive
                        ? LinearGradient(colors: [
                            theme.colorScheme.error,
                            theme.colorScheme.error.withOpacity(0.8)
                          ])
                        : null, // Use default primary gradient
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      '再考慮一下',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction(EventRegistrationStatus status) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (status == EventRegistrationStatus.none) {
        await widget.eventService.registerForEvent(widget.event.id, widget.userId);
      } else {
        await widget.eventService.unregisterFromEvent(widget.event.id, widget.userId);
      }

      if (mounted) {
        Navigator.of(context).pop(true); // Return success
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    // Simple formatter, in a real app use intl
    return '${date.month}月${date.day}日 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
