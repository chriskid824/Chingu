import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:intl/intl.dart';

class DinnerEventCard extends StatelessWidget {
  final DinnerEventModel event;
  final VoidCallback? onTap;
  final bool isWaitlist;

  const DinnerEventCard({
    super.key,
    required this.event,
    this.onTap,
    this.isWaitlist = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    final dateFormat = DateFormat('yyyy/MM/dd', 'zh_TW');
    final timeFormat = DateFormat('HH:mm', 'zh_TW');

    Color statusColor;
    String statusText;

    if (event.status == 'cancelled') {
      statusColor = theme.colorScheme.error;
      statusText = '已取消';
    } else if (event.status == 'completed') {
      statusColor = Colors.grey;
      statusText = '已結束';
    } else if (isWaitlist) {
      statusColor = Colors.orange;
      statusText = '候補中';
    } else if (event.status == 'confirmed') {
      statusColor = chinguTheme?.success ?? Colors.green;
      statusText = '已確認';
    } else {
      statusColor = theme.colorScheme.primary;
      statusText = '等待中';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: chinguTheme?.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.restaurant, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${event.maxParticipants}人晚餐聚會',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                statusText,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isWaitlist) ...[
                              const SizedBox(width: 8),
                              Text(
                                '等待遞補',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                context,
                Icons.calendar_today_rounded,
                '${dateFormat.format(event.dateTime)} ${timeFormat.format(event.dateTime)}'
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                context,
                Icons.location_on_rounded,
                event.restaurantName ?? '${event.city}${event.district}'
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                context,
                Icons.people_rounded,
                '目前 ${event.participantIds.length} / ${event.maxParticipants} 人'
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.hintColor),
        const SizedBox(width: 8),
        Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}
