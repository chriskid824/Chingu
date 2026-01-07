import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_colors_minimal.dart';

class EventsListScreenDemo extends StatelessWidget {
  const EventsListScreenDemo({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsMinimal.background,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              color: AppColorsMinimal.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              '我的預約',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColorsMinimal.textPrimary,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
          color: AppColorsMinimal.textPrimary,
        ),
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColorsMinimal.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: AppColorsMinimal.textSecondary,
                indicator: BoxDecoration(
                  gradient: AppColorsMinimal.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: '📅 即將到來'),
                  Tab(text: '📋 歷史記錄'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildEventsList(true),
                  _buildEventsList(false),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppColorsMinimal.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColorsMinimal.primary.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {},
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add_rounded, size: 28),
        ),
      ),
    );
  }
  
  Widget _buildEventsList(bool isUpcoming) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildEventCard(
          '6人晚餐聚會',
          '2025/10/15',
          '19:00',
          'NT\$ 500-800 / 人',
          '台北市信義區',
          isUpcoming,
        ),
        _buildEventCard(
          '6人晚餐聚會',
          '2025/10/18',
          '18:30',
          'NT\$ 800-1200 / 人',
          '台北市大安區',
          isUpcoming,
        ),
        if (!isUpcoming)
          _buildEventCard(
            '6人晚餐聚會',
            '2025/10/01',
            '19:30',
            'NT\$ 600-900 / 人',
            '台北市中山區',
            isUpcoming,
          ),
      ],
    );
  }
  
  Widget _buildEventCard(
    String title,
    String date,
    String time,
    String budget,
    String location,
    bool isUpcoming,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColorsMinimal.surfaceVariant),
        boxShadow: [
          BoxShadow(
            color: AppColorsMinimal.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {},
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
                      gradient: AppColorsMinimal.primaryGradient,
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
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: AppColorsMinimal.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.people_rounded,
                              size: 14,
                              color: AppColorsMinimal.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '6 人',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColorsMinimal.textSecondary,
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
                      color: isUpcoming
                          ? AppColorsMinimal.successLight
                          : AppColorsMinimal.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isUpcoming ? '已確認' : '已完成',
                      style: TextStyle(
                        color: isUpcoming
                            ? AppColorsMinimal.success
                            : AppColorsMinimal.textSecondary,
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
                  color: AppColorsMinimal.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 16,
                          color: AppColorsMinimal.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$date  $time',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColorsMinimal.textPrimary,
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
                          color: AppColorsMinimal.secondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          budget,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColorsMinimal.textSecondary,
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
                          color: AppColorsMinimal.success,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          location,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColorsMinimal.textSecondary,
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
    );
  }
}
