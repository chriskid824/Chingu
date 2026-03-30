import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:chingu/core/theme/app_colors_minimal.dart';
import 'package:chingu/providers/dinner_event_provider.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/providers/subscription_provider.dart';
import 'package:cloud_functions/cloud_functions.dart';

class BookingBottomSheet extends StatefulWidget {
  final FirebaseFunctions? functions;

  const BookingBottomSheet({
    super.key,
    this.functions,
  });

  @override
  State<BookingBottomSheet> createState() => _BookingBottomSheetState();
}

class _BookingBottomSheetState extends State<BookingBottomSheet> {
  DateTime? _selectedDate;
  bool _isBooking = false;

  // 地區選擇
  String _selectedCity = '台北市';
  String _selectedDistrict = '信義區';

  final List<String> _cities = ['台北市'];
  final Map<String, List<String>> _districts = {
    '台北市': ['信義區', '板橋區', '萬華區', '中山區'],
  };

  @override
  void initState() {
    super.initState();
    final provider = context.read<DinnerEventProvider>();
    final bookable = provider.getBookableDates();
    // 預設選中第一個未報名且可預約的日期
    for (final date in bookable) {
      if (!provider.isDateBooked(date)) {
        _selectedDate = date;
        break;
      }
    }
  }

  Future<void> _handleBooking() async {
    if (_selectedDate == null) return;

    // 前端防重複報名檢查
    final eventProvider = context.read<DinnerEventProvider>();
    if (eventProvider.isDateBooked(_selectedDate!)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('您已報名此日期，請選擇其他日期'),
            backgroundColor: AppColorsMinimal.warning,
          ),
        );
      }
      return;
    }

    setState(() => _isBooking = true);

    try {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.uid == null) throw Exception('請先登入');

      final funcs = widget.functions ?? FirebaseFunctions.instance;
      final callable = funcs.httpsCallable('bookWithValidation');
      final result = await callable.call<Map<String, dynamic>>({
        'date': _selectedDate!.toIso8601String(),
        'city': _selectedCity,
        'district': _selectedDistrict,
      });

      final subscriptionProv = context.read<SubscriptionProvider>();
      await subscriptionProv.loadSubscription(authProvider.uid!);
      final eventProvider = context.read<DinnerEventProvider>();
      await eventProvider.fetchMyEvents(authProvider.uid!);

      if (mounted) {
        Navigator.pop(context);
        final ticketType = result.data['ticketType'] ?? '';
        final remaining = result.data['remaining'];
        final msg = ticketType == 'free' && remaining != null
            ? '報名成功！剩餘免費次數：$remaining'
            : '報名成功！';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        if (e.code == 'permission-denied') {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('目前無法報名，請稍後再試')),
          );
        } else {
          // 翻譯常見錯誤碼為中文
          final friendlyMsg = _getFriendlyErrorMessage(e.code, e.message);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(friendlyMsg),
              backgroundColor: AppColorsMinimal.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('網路連線異常，請檢查網路後重試'),
            backgroundColor: AppColorsMinimal.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  String _getDateLabel(DateTime date, List<DateTime> allDates) {
    if (allDates.isEmpty) return '週四';
    final now = DateTime.now();
    final idx = allDates.indexOf(date);
    if (now.weekday <= DateTime.thursday) {
      return ['本週四', '下週四', '下下週四'][idx];
    } else {
      return ['下週四', '下下週四', '第三週四'][idx];
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<DinnerEventProvider>();
    final allDates = provider.getThursdayDates();
    final bookableDates = provider.getBookableDates();
    final reachedLimit = !provider.canBookMore;

    return Container(
      padding: const EdgeInsets.all(AppColorsMinimal.spaceXL),
      decoration: BoxDecoration(
        color: AppColorsMinimal.background,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppColorsMinimal.radiusLG),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColorsMinimal.surfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppColorsMinimal.spaceXL),
          Text('預約晚餐',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColorsMinimal.textPrimary,
            )),
          const SizedBox(height: AppColorsMinimal.spaceXL),

          // 日期選擇
          Text('選擇日期 (每週四)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColorsMinimal.textPrimary,
            )),
          const SizedBox(height: AppColorsMinimal.spaceMD),

          // 報名上限提示
          if (reachedLimit)
            Container(
              padding: const EdgeInsets.all(AppColorsMinimal.spaceMD),
              margin: const EdgeInsets.only(bottom: AppColorsMinimal.spaceMD),
              decoration: BoxDecoration(
                color: AppColorsMinimal.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppColorsMinimal.radiusMD),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColorsMinimal.error, size: 18),
                  const SizedBox(width: AppColorsMinimal.spaceSM),
                  Expanded(
                    child: Text(
                      '最多同時報名 ${DinnerEventProvider.maxActiveBookings} 場，完成或取消後可再報名',
                      style: TextStyle(fontSize: 13, color: AppColorsMinimal.error),
                    ),
                  ),
                ],
              ),
            ),

          // 日期卡片列表
          Row(
            children: allDates.asMap().entries.map((entry) {
              final idx = entry.key;
              final date = entry.value;
              final isBooked = provider.isDateBooked(date);
              final isBookable = bookableDates.contains(date);
              final isExpired = !isBookable && !isBooked;
              final isSelected = _selectedDate == date;
              final canSelect = isBookable && !isBooked && !reachedLimit;

              final label = _getDateLabel(date, allDates);
              final dateStr = DateFormat('MM/dd').format(date);

              return Expanded(
                child: GestureDetector(
                  onTap: canSelect ? () => setState(() => _selectedDate = date) : null,
                  child: Container(
                    margin: EdgeInsets.only(right: idx < allDates.length - 1 ? AppColorsMinimal.spaceSM : 0),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isBooked
                          ? AppColorsMinimal.primary.withValues(alpha: 0.1)
                          : isSelected
                              ? AppColorsMinimal.primary
                              : AppColorsMinimal.surface,
                      borderRadius: BorderRadius.circular(AppColorsMinimal.radiusMD),
                      border: Border.all(
                        color: isBooked
                            ? AppColorsMinimal.primary
                            : isSelected
                                ? AppColorsMinimal.primary
                                : isExpired || reachedLimit
                                    ? AppColorsMinimal.border
                                    : AppColorsMinimal.textTertiary,
                      ),
                      boxShadow: isSelected && canSelect
                          ? [BoxShadow(
                              color: AppColorsMinimal.primary.withValues(alpha: 0.3),
                              blurRadius: 8, offset: const Offset(0, 4))]
                          : null,
                    ),
                    child: Column(
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            color: isBooked
                                ? AppColorsMinimal.primary
                                : isSelected
                                    ? AppColorsMinimal.textInverse
                                    : isExpired || reachedLimit
                                        ? AppColorsMinimal.textTertiary
                                        : AppColorsMinimal.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: AppColorsMinimal.spaceXS),
                        Text(
                          dateStr,
                          style: TextStyle(
                            color: isBooked
                                ? AppColorsMinimal.primary.withValues(alpha: 0.7)
                                : isSelected
                                    ? AppColorsMinimal.textInverse.withValues(alpha: 0.9)
                                    : AppColorsMinimal.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        if (isBooked) ...[
                          const SizedBox(height: AppColorsMinimal.spaceXS),
                          Text('已報名',
                            style: TextStyle(fontSize: 11, color: AppColorsMinimal.primary, fontWeight: FontWeight.w600)),
                        ],
                        if (isExpired && !isBooked) ...[
                          const SizedBox(height: AppColorsMinimal.spaceXS),
                          Text('已截止', style: TextStyle(fontSize: 11, color: AppColorsMinimal.textTertiary)),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // 地點選擇（2 個 Dropdown）
          Text('用餐地點',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColorsMinimal.textPrimary,
            )),
          const SizedBox(height: AppColorsMinimal.spaceMD),
          Row(
            children: [
              // 城市 Dropdown
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppColorsMinimal.spaceMD),
                  decoration: BoxDecoration(
                    color: AppColorsMinimal.surface,
                    borderRadius: BorderRadius.circular(AppColorsMinimal.radiusMD),
                    border: Border.all(color: AppColorsMinimal.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCity,
                      isExpanded: true,
                      items: _cities.map((city) {
                        return DropdownMenuItem(
                          value: city,
                          child: Text(city),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCity = value;
                            _selectedDistrict = _districts[value]!.first;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppColorsMinimal.spaceMD),
              // 地區 Dropdown
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppColorsMinimal.spaceMD),
                  decoration: BoxDecoration(
                    color: AppColorsMinimal.surface,
                    borderRadius: BorderRadius.circular(AppColorsMinimal.radiusMD),
                    border: Border.all(color: AppColorsMinimal.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedDistrict,
                      isExpanded: true,
                      items: (_districts[_selectedCity] ?? []).map((district) {
                        final isEnabled = _selectedCity == '台北市' && district == '信義區';
                        return DropdownMenuItem(
                          value: district,
                          enabled: isEnabled,
                          child: Row(
                            children: [
                              Text(
                                district,
                                style: TextStyle(
                                  color: isEnabled ? AppColorsMinimal.textPrimary : AppColorsMinimal.textTertiary,
                                ),
                              ),
                              if (!isEnabled)
                                Padding(
                                  padding: const EdgeInsets.only(left: AppColorsMinimal.spaceSM),
                                  child: Icon(Icons.lock, size: 12, color: AppColorsMinimal.textTertiary),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedDistrict = value);
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 用餐說明
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColorsMinimal.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(AppColorsMinimal.radiusMD),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.payments_rounded, size: 16, color: AppColorsMinimal.primary),
                    const SizedBox(width: AppColorsMinimal.spaceSM),
                    Expanded(
                      child: Text('餐費各付各的（Go Dutch），App 僅負責配對',
                        style: TextStyle(fontSize: 12, color: AppColorsMinimal.textSecondary)),
                    ),
                  ],
                ),
                const SizedBox(height: AppColorsMinimal.spaceSM),
                Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 16, color: AppColorsMinimal.primary),
                    const SizedBox(width: AppColorsMinimal.spaceSM),
                    Expanded(
                      child: Text('智能配對 · 性別平衡 · 匿名保護',
                        style: TextStyle(fontSize: 12, color: AppColorsMinimal.textSecondary)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppColorsMinimal.spaceLG),

          // 確認按鈕
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: (_isBooking || _selectedDate == null || reachedLimit)
                  ? null
                  : _handleBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorsMinimal.primary,
                foregroundColor: AppColorsMinimal.textInverse,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppColorsMinimal.radiusMD),
                ),
                elevation: 0,
              ),
              child: _isBooking
                  ? const SizedBox(width: 24, height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('確認報名',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: AppColorsMinimal.spaceLG),
        ],
      ),
    );
  }

  String _getFriendlyErrorMessage(String code, String? message) {
    switch (code) {
      case 'not-found':
        return '找不到活動，請重新整理後再試';
      case 'already-exists':
        return '你已報名此場次';
      case 'resource-exhausted':
        return '此場次名額已滿';
      case 'failed-precondition':
        return '報名條件不符，請確認是否已達上限或已截止';
      case 'unauthenticated':
        return '請先登入再報名';
      case 'deadline-exceeded':
        return '報名已截止';
      case 'unavailable':
        return '伺服器暫時無法連線，請稍後再試';
      case 'internal':
        return '伺服器發生錯誤，請稍後再試';
      default:
        return message ?? '報名失敗，請稍後再試';
    }
  }
}
