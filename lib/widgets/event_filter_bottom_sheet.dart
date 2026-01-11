import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class EventFilterBottomSheet extends StatefulWidget {
  final String? initialCity;
  final DateTimeRange? initialDateRange;
  final String? initialStatus;
  final Function(String? city, DateTimeRange? dateRange, String? status) onApply;
  final VoidCallback onReset;

  const EventFilterBottomSheet({
    super.key,
    this.initialCity,
    this.initialDateRange,
    this.initialStatus,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<EventFilterBottomSheet> createState() => _EventFilterBottomSheetState();
}

class _EventFilterBottomSheetState extends State<EventFilterBottomSheet> {
  String? _selectedCity;
  DateTimeRange? _selectedDateRange;
  String? _selectedStatus;

  final List<String> _cities = [
    '台北市',
    '新北市',
    '桃園市',
    '台中市',
    '台南市',
    '高雄市',
  ];

  final Map<String, String> _statusOptions = {
    'pending': '等待配對',
    'confirmed': '已確認',
    'completed': '已完成',
    'cancelled': '已取消',
  };

  @override
  void initState() {
    super.initState();
    _selectedCity = widget.initialCity;
    _selectedDateRange = widget.initialDateRange;
    _selectedStatus = widget.initialStatus;
  }

  Future<void> _pickDateRange() async {
    final theme = Theme.of(context);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2026),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.colorScheme.primary,
              onPrimary: Colors.white,
              surface: theme.cardColor,
              onSurface: theme.colorScheme.onSurface,
            ),
            datePickerTheme: DatePickerThemeData(
              headerBackgroundColor: theme.colorScheme.primary,
              headerForegroundColor: Colors.white,
              backgroundColor: theme.cardColor,
              surfaceTintColor: Colors.transparent,
              dayOverlayColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return theme.colorScheme.primary.withOpacity(0.2);
                }
                return null;
              }),
              rangeSelectionBackgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '篩選活動',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedCity = null;
                    _selectedDateRange = null;
                    _selectedStatus = null;
                  });
                  widget.onReset();
                  Navigator.pop(context);
                },
                child: Text(
                  '重置',
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // City Filter
          Text(
            '城市',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _cities.map((city) {
              final isSelected = _selectedCity == city;
              return ChoiceChip(
                label: Text(city),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedCity = selected ? city : null;
                  });
                },
                selectedColor: theme.colorScheme.primary.withOpacity(0.1),
                backgroundColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                labelStyle: TextStyle(
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                  ),
                ),
                showCheckmark: false,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Date Range Filter
          Text(
            '日期範圍',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickDateRange,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedDateRange != null
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 20,
                    color: _selectedDateRange != null
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedDateRange != null
                          ? '${DateFormat('yyyy/MM/dd').format(_selectedDateRange!.start)} - ${DateFormat('yyyy/MM/dd').format(_selectedDateRange!.end)}'
                          : '選擇日期範圍',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _selectedDateRange != null
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ),
                  if (_selectedDateRange != null)
                    InkWell(
                      onTap: () => setState(() => _selectedDateRange = null),
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Status Filter (Activity Type)
          Text(
            '活動狀態',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _statusOptions.entries.map((entry) {
              final isSelected = _selectedStatus == entry.key;
              return ChoiceChip(
                label: Text(entry.value),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedStatus = selected ? entry.key : null;
                  });
                },
                selectedColor: theme.colorScheme.primary.withOpacity(0.1),
                backgroundColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                labelStyle: TextStyle(
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                  ),
                ),
                showCheckmark: false,
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          // Apply Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(_selectedCity, _selectedDateRange, _selectedStatus);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                padding: EdgeInsets.zero,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ).copyWith(
                elevation: WidgetStateProperty.all(0),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: chinguTheme?.primaryGradient,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Container(
                  alignment: Alignment.center,
                  child: const Text(
                    '應用篩選',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
