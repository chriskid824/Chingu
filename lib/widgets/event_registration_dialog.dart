import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/providers/auth_provider.dart';

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
  final DinnerEventService _eventService = DinnerEventService();

  Future<void> _handleAction(String userId, bool isRegistering) async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (isRegistering) {
        final status = await _eventService.registerForEvent(widget.event.id, userId);
        if (mounted) {
           String message = status == EventRegistrationStatus.registered
              ? '報名成功！'
              : '已加入候補名單';
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
           Navigator.of(context).pop(true);
        }
      } else {
        await _eventService.unregisterFromEvent(widget.event.id, userId);
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已取消報名')));
           Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.uid;

    if (userId == null) {
      return const AlertDialog(title: Text('錯誤'), content: Text('未登入'));
    }

    final isRegistered = widget.event.participantIds.contains(userId);
    final isWaitlisted = widget.event.waitingListIds.contains(userId);
    final isFull = widget.event.isFull;

    String title = '活動報名';
    String content = '確定要參加此活動嗎？\n\n時間: ${widget.event.dateTime.toString().split('.')[0]}\n地點: ${widget.event.city} ${widget.event.district}';
    String actionLabel = '報名參加';
    Color actionColor = Theme.of(context).primaryColor;
    bool isDestructive = false;

    if (isRegistered) {
      title = '取消報名';
      content = '確定要取消報名嗎？\n\n注意：活動前24小時內不可取消。';
      actionLabel = '取消報名';
      actionColor = Colors.red;
      isDestructive = true;
    } else if (isWaitlisted) {
      title = '取消候補';
      content = '確定要退出候補名單嗎？';
      actionLabel = '退出候補';
      actionColor = Colors.red;
      isDestructive = true;
    } else if (isFull) {
      title = '加入候補';
      content = '此活動名額已滿，是否加入候補名單？\n\n如果有空位釋出，您將自動遞補。';
      actionLabel = '加入候補';
    }

    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : () => _handleAction(userId, !isDestructive),
          style: ElevatedButton.styleFrom(
            backgroundColor: actionColor,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(actionLabel),
        ),
      ],
    );
  }
}
