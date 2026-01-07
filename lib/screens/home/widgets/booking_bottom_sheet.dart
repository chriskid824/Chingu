import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/providers/dinner_event_provider.dart';
import 'package:chingu/providers/auth_provider.dart';

class BookingBottomSheet extends StatefulWidget {
  const BookingBottomSheet({super.key});

  @override
  State<BookingBottomSheet> createState() => _BookingBottomSheetState();
}

class _BookingBottomSheetState extends State<BookingBottomSheet> {
  late List<DateTime> _availableDates;
  DateTime? _selectedDate;
  String _selectedCity = '台北市';
  String _selectedDistrict = '信義區';
  bool _isBooking = false;

  final List<String> _cities = ['台北市', '新北市', '台中市', '高雄市'];
  final Map<String, List<String>> _districts = {
    '台北市': ['信義區', '大安區', '中山區', '松山區'],
    '新北市': ['板橋區', '新店區', '永和區'],
    '台中市': ['西屯區', '南屯區'],
    '高雄市': ['左營區', '鼓山區'],
  };

  @override
  void initState() {
    super.initState();
    final provider = context.read<DinnerEventProvider>();
    _availableDates = provider.getBookableDates();
    // 預設選中第一個可用的日期
    if (_availableDates.isNotEmpty) {
      _selectedDate = _availableDates.first; 
    }
  }

  Future<void> _handleBooking() async {
    if (_selectedDate == null) return;

    setState(() {
      _isBooking = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final eventProvider = context.read<DinnerEventProvider>();

      if (authProvider.uid == null) {
        throw Exception('請先登入');
      }

      final success = await eventProvider.bookEvent(
        userId: authProvider.uid!,
        date: _selectedDate!,
        city: _selectedCity,
        district: _selectedDistrict,
      );

      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('報名成功！')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(eventProvider.errorMessage ?? '報名失敗')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('發生錯誤: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBooking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    final provider = context.read<DinnerEventProvider>();
    final allThursdayDates = provider.getThursdayDates();

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
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '預約晚餐',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // 日期選擇
          Text(
            '選擇日期 (每週四)',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (_availableDates.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('目前沒有可預約的時段，\n請下週再來查看！'),
                  ),
                ],
              ),
            )
          else
            Row(
              children: _availableDates.map((date) {
                final isSelected = _selectedDate == date;
                
                // 判斷顯示標籤
                String label = '週四';
                if (allThursdayDates.isNotEmpty && date == allThursdayDates[0]) {
                  // 如果是第一個日期（本週四或下週四）
                  if (DateTime.now().weekday <= DateTime.thursday) {
                    label = '本週四';
                  } else {
                    label = '下週四';
                  }
                } else if (allThursdayDates.length > 1 && date == allThursdayDates[1]) {
                  // 如果是第二個日期
                   if (DateTime.now().weekday <= DateTime.thursday) {
                    label = '下週四';
                  } else {
                    label = '下下週四';
                  }
                }
                
                final dateStr = DateFormat('MM/dd').format(date);
                final isFirstItem = date == _availableDates.first;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDate = date;
                      });
                    },
                  child: Container(
                    margin: EdgeInsets.only(right: isFirstItem ? 12 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? theme.colorScheme.primary 
                          : theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected 
                            ? theme.colorScheme.primary 
                            : Colors.grey[300]!,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: theme.colorScheme.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : null,
                    ),
                    child: Column(
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateStr,
                          style: TextStyle(
                            color: isSelected ? Colors.white.withOpacity(0.9) : Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          
          // 地點選擇
          Text(
            '選擇地點',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
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
                        // 暫時只開放信義區
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
                          setState(() {
                            _selectedDistrict = value;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // 確認按鈕
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isBooking ? null : _handleBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isBooking
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      '確認報名',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
