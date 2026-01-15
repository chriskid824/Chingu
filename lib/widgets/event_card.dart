import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';

class EventCard extends StatefulWidget {
  final String title;
  final String date;
  final String time;
  final String budget;
  final String location;
  final bool isUpcoming;
  final String? statusText;
  final Color? statusColor;
  final VoidCallback? onTap;

  const EventCard({
    super.key,
    required this.title,
    required this.date,
    required this.time,
    required this.budget,
    required this.location,
    required this.isUpcoming,
    this.statusText,
    this.statusColor,
    this.onTap,
  });

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(_isPressed ? 0.02 : 0.05),
                blurRadius: _isPressed ? 4 : 8,
                offset: _isPressed ? const Offset(0, 1) : const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: theme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.1)),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onTap,
              onHighlightChanged: (value) => setState(() => _isPressed = value),
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
                          child: const Icon(
                            Icons.restaurant,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.people_rounded,
                                    size: 14,
                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '6 人',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: widget.statusColor != null
                                ? widget.statusColor!.withOpacity(0.1)
                                : widget.isUpcoming
                                    ? (chinguTheme?.success ?? Colors.green).withOpacity(0.1)
                                    : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.statusText ?? (widget.isUpcoming ? '已確認' : '已完成'),
                            style: TextStyle(
                              color: widget.statusColor ?? (widget.isUpcoming
                                  ? (chinguTheme?.success ?? Colors.green)
                                  : theme.colorScheme.onSurface.withOpacity(0.6)),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${widget.date}  ${widget.time}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.payments_rounded,
                                size: 16,
                                color: theme.colorScheme.secondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.budget,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 16,
                                color: chinguTheme?.success ?? Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.location,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
