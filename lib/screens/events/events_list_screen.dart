import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/widgets/event_card.dart';
import 'package:chingu/widgets/animated_tab_bar.dart';
import 'package:chingu/widgets/event_filter_bottom_sheet.dart';
import 'package:chingu/providers/dinner_event_provider.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/models/dinner_event_model.dart';

class EventsListScreen extends StatefulWidget {
  const EventsListScreen({super.key});

  @override
  State<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends State<EventsListScreen> {
  int _selectedIndex = 0;
  late PageController _pageController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);

    // 初始加載數據
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().uid;
      if (userId != null) {
        // 先清除之前的過濾條件，確保看到所有活動
        context.read<DinnerEventProvider>().clearFilters();
        context.read<DinnerEventProvider>().fetchMyEvents(userId);
      }
    });

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final provider = context.read<DinnerEventProvider>();
    provider.setFilters(
      city: provider.filterCity,
      dateRange: provider.filterDateRange,
      status: provider.filterStatus,
      searchQuery: _searchController.text,
    );
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showFilterBottomSheet() {
    final provider = context.read<DinnerEventProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EventFilterBottomSheet(
        initialCity: provider.filterCity,
        initialDateRange: provider.filterDateRange,
        initialStatus: provider.filterStatus,
        onApply: (city, dateRange, status) {
          provider.setFilters(
            city: city,
            dateRange: dateRange,
            status: status,
            searchQuery: _searchController.text,
          );
        },
        onReset: () {
          _searchController.clear(); // 也清除搜尋框
          provider.clearFilters();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              '我的預約',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
          color: theme.colorScheme.onSurface,
        ),
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.1),
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: '搜尋活動名稱或描述...',
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        isDense: true,
                        // Remove default paddings
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: _showFilterBottomSheet,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: chinguTheme?.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AnimatedTabBar(
              tabs: const ['📅 即將到來', '📋 歷史記錄'],
              selectedIndex: _selectedIndex,
              onTabSelected: _onTabSelected,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Consumer<DinnerEventProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.myEvents.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.errorMessage != null) {
                  return Center(child: Text('發生錯誤: ${provider.errorMessage}'));
                }

                return PageView(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  children: [
                    _buildEventsList(context, provider.filteredMyEvents, true),
                    _buildEventsList(context, provider.filteredMyEvents, false),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList(BuildContext context, List<DinnerEventModel> allEvents, bool isUpcoming) {
    final now = DateTime.now();
    // 這裡我們需要同時應用 filteredMyEvents 的過濾結果以及 Upcoming/History 的區分
    // filteredMyEvents 已經包含了搜尋和篩選器的結果
    final events = allEvents.where((event) {
      if (isUpcoming) {
        // 未來: 活動時間在現在之後
        return event.dateTime.isAfter(now);
      } else {
        // 歷史: 活動時間在現在之前
        return event.dateTime.isBefore(now);
      }
    }).toList();

    // 排序：即將到來的按時間升序（最近的在前），歷史的按時間降序（最近的在前）
    events.sort((a, b) {
      if (isUpcoming) {
        return a.dateTime.compareTo(b.dateTime);
      } else {
        return b.dateTime.compareTo(a.dateTime);
      }
    });

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUpcoming ? Icons.event_available_rounded : Icons.history_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              isUpcoming ? '暫無即將到來的活動' : '暫無歷史活動',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return EventCard(
          title: event.notes?.isNotEmpty == true ? event.notes! : '晚餐聚會',
          date: DateFormat('yyyy/MM/dd').format(event.dateTime),
          time: DateFormat('HH:mm').format(event.dateTime),
          budget: '${event.budgetRangeText} / 人',
          location: '${event.city}${event.district}',
          isUpcoming: isUpcoming,
          onTap: () {
            Navigator.of(context).pushNamed(
              AppRoutes.eventDetail,
              arguments: event.id, // 雖然目前 detail screen 沒用，但傳過去是好的
            );
          },
        );
      },
    );
  }
}
