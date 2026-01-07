import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_colors_minimal.dart';

class CreateEventScreenDemo extends StatelessWidget {
  const CreateEventScreenDemo({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsMinimal.background,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.add_circle_rounded, color: AppColorsMinimal.primary, size: 24),
            const SizedBox(width: 8),
            const Text('建立晚餐預約', style: TextStyle(fontWeight: FontWeight.bold, color: AppColorsMinimal.textPrimary)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColorsMinimal.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_month_rounded, color: AppColorsMinimal.primary, size: 20),
                const SizedBox(width: 8),
                const Text('日期與時間', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColorsMinimal.textPrimary)),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: InputDecoration(
                labelText: '日期',
                hintText: '選擇日期',
                prefixIcon: Icon(Icons.calendar_today_rounded, color: AppColorsMinimal.primary),
                filled: true,
                fillColor: AppColorsMinimal.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColorsMinimal.surfaceVariant)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColorsMinimal.surfaceVariant)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColorsMinimal.primary, width: 2)),
              ),
              readOnly: true,
              onTap: () {},
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                labelText: '時間',
                hintText: '選擇時間',
                prefixIcon: Icon(Icons.access_time_rounded, color: AppColorsMinimal.secondary),
                filled: true,
                fillColor: AppColorsMinimal.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColorsMinimal.surfaceVariant)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColorsMinimal.surfaceVariant)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColorsMinimal.secondary, width: 2)),
              ),
              readOnly: true,
              onTap: () {},
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(Icons.payments_rounded, color: AppColorsMinimal.success, size: 20),
                const SizedBox(width: 8),
                const Text('預算範圍', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColorsMinimal.textPrimary)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildBudgetChip('NT\$ 300-500', false),
                _buildBudgetChip('NT\$ 500-800', true),
                _buildBudgetChip('NT\$ 800-1200', false),
                _buildBudgetChip('NT\$ 1200+', false),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(Icons.location_on_rounded, color: AppColorsMinimal.warning, size: 20),
                const SizedBox(width: 8),
                const Text('地點偏好', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColorsMinimal.textPrimary)),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: InputDecoration(
                labelText: '地區',
                hintText: '例如：信義區、大安區',
                prefixIcon: Icon(Icons.location_city_rounded, color: AppColorsMinimal.warning),
                filled: true,
                fillColor: AppColorsMinimal.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColorsMinimal.surfaceVariant)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColorsMinimal.surfaceVariant)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColorsMinimal.warning, width: 2)),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(Icons.edit_note_rounded, color: AppColorsMinimal.textSecondary, size: 20),
                const SizedBox(width: 8),
                const Text('備註（選填）', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColorsMinimal.textPrimary)),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '您想說的話...',
                filled: true,
                fillColor: AppColorsMinimal.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColorsMinimal.surfaceVariant)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColorsMinimal.surfaceVariant)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColorsMinimal.primary, width: 2)),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                gradient: AppColorsMinimal.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: AppColorsMinimal.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
              ),
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.white),
                    const SizedBox(width: 8),
                    const Text('建立預約', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBudgetChip(String label, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: selected ? AppColorsMinimal.successGradient : null,
        color: selected ? null : AppColorsMinimal.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? AppColorsMinimal.success : AppColorsMinimal.surfaceVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selected) const Icon(Icons.check, size: 16, color: Colors.white),
          if (selected) const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: selected ? Colors.white : AppColorsMinimal.textSecondary)),
        ],
      ),
    );
  }
}
