import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
            backgroundColor: Colors.orange.shade700,
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
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('網路連線異常，請檢查網路後重試'),
            backgroundColor: Colors.red.shade700,
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
    final theme = Theme.of(context);
    final provider = context.read<DinnerEventProvider>();
    final allDates = provider.getThursdayDates();
    final bookableDates = provider.getBookableDates();
    final reachedLimit = !provider.canBookMore;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('預約晚餐',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          
          // 日期選擇
          Text('選擇日期 (每週四)',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          // 報名上限提示
          if (reachedLimit)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: theme.colorScheme.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '最多同時報名 ${DinnerEventProvider.maxActiveBookings} 場，完成或取消後可再報名',
                      style: TextStyle(fontSize: 13, color: theme.colorScheme.error),
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
                    margin: EdgeInsets.only(right: idx < allDates.length - 1 ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isBooked
                          ? theme.colorScheme.primary.withValues(alpha: 0.1)
                          : isSelected
                              ? theme.colorScheme.primary
                              : theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isBooked
                            ? theme.colorScheme.primary
                            : isSelected
                                ? theme.colorScheme.primary
                                : isExpired || reachedLimit
                                    ? Colors.grey[300]!
                                    : Colors.grey[400]!,
                      ),
                      boxShadow: isSelected && canSelect
                          ? [BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 8, offset: const Offset(0, 4))]
                          : null,
                    ),
                    child: Column(
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            color: isBooked
                                ? theme.colorScheme.primary
                                : isSelected
                                    ? Colors.white
                                    : isExpired || reachedLimit
                                        ? Colors.grey
                                        : theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateStr,
                          style: TextStyle(
                            color: isBooked
                                ? theme.colorScheme.primary.withValues(alpha: 0.7)
                                : isSelected
                                    ? Colors.white.withValues(alpha: 0.9)
                                    : Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                        if (isBooked) ...[
                          const SizedBox(height: 4),
                          Text('已報名 ✅',
                            style: TextStyle(fontSize: 11, color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
                        ],
                        if (isExpired && !isBooked) ...[
                          const SizedBox(height: 4),
                          const Text('已截止', style: TextStyle(fontSize: 11, color: Colors.grey)),
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
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              // 城市 Dropdown
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
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
              const SizedBox(width: 12),
              // 地區 Dropdown
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
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
                                  color: isEnabled ? null : Colors.grey,
                                ),
                              ),
                              if (!isEnabled)
                                const Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: Icon(Icons.lock, size: 12, color: Colors.grey),
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
              color: theme.colorScheme.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.payments_rounded, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('餐費各付各的（Go Dutch），App 僅負責配對',
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('🧠 智能配對 · 👫 性別平衡 · 🔒 匿名保護',
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 確認按鈕
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: (_isBooking || _selectedDate == null || reachedLimit)
                  ? null
                  : _handleBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isBooking
                  ? const SizedBox(width: 24, height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('確認報名',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
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
