import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/explore_filter.dart';
import 'package:chingu/providers/dinner_event_provider.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/widgets/event_card.dart';
import 'package:intl/intl.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  DateTime? _selectedDate;
  String? _selectedCity = '台北市'; // Default to Taipei
  String? _selectedDistrict;
  int? _selectedBudget;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Fetch initial recommendations if possible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performSearch();
    });
  }

  Future<void> _performSearch() async {
    if (_selectedCity == null) return;

    // Default budget if not selected (or handle in provider)
    final budget = _selectedBudget ?? 1; // Default to 500-800

    setState(() {
      _isSearching = true;
    });

    final provider = context.read<DinnerEventProvider>();
    await provider.fetchRecommendedEvents(
      city: _selectedCity!,
      budgetRange: budget,
    );

    setState(() {
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<DinnerEventProvider>();

    // Client-side filtering for date and district
    List<DinnerEventModel> events = provider.recommendedEvents;

    if (_selectedDate != null) {
      events = events.where((e) {
        return e.dateTime.year == _selectedDate!.year &&
            e.dateTime.month == _selectedDate!.month &&
            e.dateTime.day == _selectedDate!.day;
      }).toList();
    }

    if (_selectedDistrict != null) {
      events = events.where((e) => e.district == _selectedDistrict).toList();
    }

    // Also filter by budget if selected (provider already does it, but to be safe if provider logic changes)
    if (_selectedBudget != null) {
      events = events.where((e) => e.budgetRange == _selectedBudget).toList();
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          '探索活動',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExploreFilter(
              selectedDate: _selectedDate,
              onDateSelected: (date) => setState(() => _selectedDate = date),
              selectedCity: _selectedCity,
              selectedDistrict: _selectedDistrict,
              onLocationSelected: (city, district) {
                setState(() {
                  _selectedCity = city;
                  _selectedDistrict = district;
                });
              },
              selectedBudget: _selectedBudget,
              onBudgetSelected: (budget) => setState(() => _selectedBudget = budget),
              onApply: _performSearch,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Text(
                  '推薦活動',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_isSearching)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            if (provider.isLoading && _isSearching)
               Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(
                     valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                  ),
                ),
              )
            else if (events.isEmpty)
              _buildEmptyState(theme)
            else
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: events.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return EventCard(event: events[index]);
                },
              ),

              const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.event_busy_rounded,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            '沒有找到符合條件的活動',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '試試看調整篩選條件？',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }
}
