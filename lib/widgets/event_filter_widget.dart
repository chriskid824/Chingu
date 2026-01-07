import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';

class EventFilterWidget extends StatelessWidget {
  final String selectedDistrict;
  final ValueChanged<String> onDistrictSelected;

  const EventFilterWidget({
    super.key,
    required this.selectedDistrict,
    required this.onDistrictSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final districts = ['全部', '信義區', '大安區', '中山區'];

    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: districts.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final district = districts[index];
          final isSelected = district == selectedDistrict;

          return ActionChip(
            label: Text(district),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : theme.colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            backgroundColor: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceContainerHighest,
            side: BorderSide(
              color: isSelected
                  ? Colors.transparent
                  : theme.colorScheme.outline.withOpacity(0.1),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            onPressed: () => onDistrictSelected(district),
          );
        },
      ),
    );
  }
}
