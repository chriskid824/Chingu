import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_colors_minimal.dart';

class PreferencesScreenDemo extends StatelessWidget {
  const PreferencesScreenDemo({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsMinimal.background,
      appBar: AppBar(
        title: const Text('配對偏好', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColorsMinimal.background,
        foregroundColor: AppColorsMinimal.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: List.generate(4, (index) {
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      gradient: index <= 2 ? AppColorsMinimal.primaryGradient : null,
                      color: index <= 2 ? null : AppColorsMinimal.surfaceVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('步驟 3/4', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColorsMinimal.textTertiary)),
                  const SizedBox(height: 8),
                  Text(
                    '配對偏好設定',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColorsMinimal.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text('年齡範圍', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: AppColorsMinimal.textPrimary)),
                  const SizedBox(height: 8),
                  RangeSlider(
                    values: const RangeValues(25, 35),
                    min: 18,
                    max: 60,
                    divisions: 42,
                    labels: const RangeLabels('25', '35'),
                    onChanged: (v) {},
                    activeColor: AppColorsMinimal.primary,
                  ),
                  const SizedBox(height: 24),
                  Text('預算範圍', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: AppColorsMinimal.textPrimary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['NT\$ 300-500', 'NT\$ 500-800', 'NT\$ 800-1200', 'NT\$ 1200+']
                        .map((budget) => ChoiceChip(
                              label: Text(budget),
                              selected: false,
                              onSelected: (v) {},
                              selectedColor: AppColorsMinimal.primary,
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  Text('配對類型', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: AppColorsMinimal.textPrimary)),
                  const SizedBox(height: 8),
                  Column(
                    children: [
                      RadioListTile(
                        title: const Text('異性配對'),
                        value: 'opposite',
                        groupValue: 'opposite',
                        onChanged: (v) {},
                        activeColor: AppColorsMinimal.primary,
                      ),
                      RadioListTile(
                        title: const Text('同性配對'),
                        value: 'same',
                        groupValue: 'opposite',
                        onChanged: (v) {},
                        activeColor: AppColorsMinimal.primary,
                      ),
                      RadioListTile(
                        title: const Text('不限'),
                        value: 'any',
                        groupValue: 'opposite',
                        onChanged: (v) {},
                        activeColor: AppColorsMinimal.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColorsMinimal.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColorsMinimal.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('下一步', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}



