import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/dinner_group_model.dart';
import '../../models/restaurant_model.dart';
import '../providers/admin_groups_provider.dart';
import '../providers/admin_restaurants_provider.dart';

class GroupCard extends StatelessWidget {
  final DinnerGroupModel group;
  const GroupCard({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final groupsProv = context.watch<AdminGroupsProvider>();
    final users = groupsProv.participantsByGroup[group.id] ?? const [];
    final dietary = groupsProv.dietaryUnion(group.id);
    final budgets = groupsProv.budgetIntersection(group.id);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF2E5364),
                  child: Text(
                    '${group.participantIds.length}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '小組 ${group.id.substring(0, 6)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        group.status,
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                _bookingChip(context),
              ],
            ),
            const Divider(height: 24),
            Text('參與者 (${users.length})', style: _labelStyle),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final u in users)
                  Chip(
                    label: Text(
                      '${u.name} · ${u.age}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '飲食禁忌：${dietary.isEmpty ? "無" : dietary.join("、")}',
              style: _miniStyle,
            ),
            Text(
              '預算等級交集：${budgets.isEmpty ? "無" : budgets.join(", ")}',
              style: _miniStyle,
            ),
            const Spacer(),
            const Divider(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    group.restaurantName ?? '尚未指定餐廳',
                    style: TextStyle(
                      fontSize: 13,
                      color: group.restaurantName != null ? Colors.black87 : Colors.black45,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.restaurant, size: 16),
                  label: Text(group.restaurantId == null ? '指定' : '更換'),
                  onPressed: () => _openAssignDialog(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _bookingChip(BuildContext context) {
    final (color, label) = switch (group.bookingStatus) {
      'pending' => (Colors.orange, '待訂位'),
      'confirmed' => (Colors.green, '已訂位'),
      'failed' => (Colors.red, '訂位失敗'),
      _ => (Colors.grey, '未指定'),
    };
    return InkWell(
      onTap: () => _openBookingMenu(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 11)),
      ),
    );
  }

  void _openBookingMenu(BuildContext context) async {
    final groupsProv = context.read<AdminGroupsProvider>();
    final result = await showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(800, 200, 0, 0),
      items: const [
        PopupMenuItem(value: 'pending', child: Text('待訂位')),
        PopupMenuItem(value: 'confirmed', child: Text('已訂位')),
        PopupMenuItem(value: 'failed', child: Text('訂位失敗')),
      ],
    );
    if (result != null) await groupsProv.setBookingStatus(group.id, result);
  }

  Future<void> _openAssignDialog(BuildContext context) async {
    final groupsProv = context.read<AdminGroupsProvider>();
    final restaurantsProv = context.read<AdminRestaurantsProvider>();
    final dietary = groupsProv.dietaryUnion(group.id);
    final budgets = groupsProv.budgetIntersection(group.id);
    final candidates = restaurantsProv.filterFor(
      requiredDietary: dietary,
      allowedBudgetLevels: budgets,
    );

    final picked = await showDialog<RestaurantModel>(
      context: context,
      builder: (_) => _RestaurantPickerDialog(candidates: candidates),
    );
    if (picked != null) await groupsProv.assignRestaurant(group.id, picked);
  }

  static const _labelStyle = TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600);
  static const _miniStyle = TextStyle(fontSize: 12, color: Colors.black54);
}

class _RestaurantPickerDialog extends StatelessWidget {
  final List<RestaurantModel> candidates;
  const _RestaurantPickerDialog({required this.candidates});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '選擇餐廳（已自動排除近 14 天指定過的）',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: candidates.isEmpty
                  ? const Center(child: Text('沒有符合條件的餐廳'))
                  : ListView.separated(
                      itemCount: candidates.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final r = candidates[i];
                        return ListTile(
                          title: Text(r.name),
                          subtitle: Text('${r.address}\n${r.budgetLevelText}'),
                          isThreeLine: true,
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.pop(context, r),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
