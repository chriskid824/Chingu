import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/providers/dinner_event_provider.dart';
import 'package:chingu/providers/auth_provider.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cityController = TextEditingController(text: '台北市'); // 預設值
  final _districtController = TextEditingController();
  final _notesController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _selectedBudget = 1; // 預設: 500-800
  bool _isLoading = false;

  @override
  void dispose() {
    _cityController.dispose();
    _districtController.dispose();
    _notesController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final theme = Theme.of(context);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.colorScheme.primary,
              onPrimary: Colors.white,
              onSurface: theme.colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy/MM/dd').format(picked);
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final theme = Theme.of(context);
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 19, minute: 0),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.colorScheme.primary,
              onPrimary: Colors.white,
              onSurface: theme.colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _timeController.text = picked.format(context);
      });
    }
  }

  Future<void> _handleCreate() async {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('請選擇日期和時間'),
          backgroundColor: theme.colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 組合完整的 DateTime
      final dateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final authProvider = context.read<AuthProvider>();
      final eventProvider = context.read<DinnerEventProvider>();

      if (authProvider.uid == null) {
        throw Exception('請先登入');
      }

      final success = await eventProvider.createEvent(
        creatorId: authProvider.uid!,
        dateTime: dateTime,
        budgetRange: _selectedBudget,
        city: _cityController.text.trim(),
        district: _districtController.text.trim(),
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('活動創建成功！🎉'),
            backgroundColor: chinguTheme?.success ?? Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(eventProvider.errorMessage ?? '創建失敗'),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: theme.colorScheme.error,
        ),
      );
    }
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
            Icon(Icons.add_circle_rounded, color: theme.colorScheme.primary, size: 24),
            const SizedBox(width: 8),
            Text('建立晚餐預約', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 日期與時間
              Row(
                children: [
                  Icon(Icons.calendar_month_rounded, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('日期與時間', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dateController,
                decoration: InputDecoration(
                  labelText: '日期',
                  hintText: '選擇日期',
                  prefixIcon: Icon(Icons.calendar_today_rounded, color: theme.colorScheme.primary),
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: chinguTheme?.surfaceVariant ?? theme.dividerColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: chinguTheme?.surfaceVariant ?? theme.dividerColor)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.colorScheme.primary, width: 2)),
                ),
                readOnly: true,
                onTap: () => _selectDate(context),
                validator: (value) => value == null || value.isEmpty ? '請選擇日期' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _timeController,
                decoration: InputDecoration(
                  labelText: '時間',
                  hintText: '選擇時間',
                  prefixIcon: Icon(Icons.access_time_rounded, color: chinguTheme?.secondary ?? theme.colorScheme.secondary),
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: chinguTheme?.surfaceVariant ?? theme.dividerColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: chinguTheme?.surfaceVariant ?? theme.dividerColor)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: chinguTheme?.secondary ?? theme.colorScheme.secondary, width: 2)),
                ),
                readOnly: true,
                onTap: () => _selectTime(context),
                validator: (value) => value == null || value.isEmpty ? '請選擇時間' : null,
              ),
              const SizedBox(height: 24),
              
              // 預算範圍
              Row(
                children: [
                  Icon(Icons.payments_rounded, color: chinguTheme?.success ?? Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text('預算範圍', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildBudgetChip('NT\$ 300-500', 0, theme),
                  _buildBudgetChip('NT\$ 500-800', 1, theme),
                  _buildBudgetChip('NT\$ 800-1200', 2, theme),
                  _buildBudgetChip('NT\$ 1200+', 3, theme),
                ],
              ),
              const SizedBox(height: 24),
              
              // 地點偏好
              Row(
                children: [
                  Icon(Icons.location_on_rounded, color: chinguTheme?.warning ?? Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Text('地點偏好', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: '城市',
                  hintText: '例如：台北市',
                  prefixIcon: Icon(Icons.location_city_rounded, color: chinguTheme?.warning ?? Colors.orange),
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: chinguTheme?.surfaceVariant ?? theme.dividerColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: chinguTheme?.surfaceVariant ?? theme.dividerColor)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: chinguTheme?.warning ?? Colors.orange, width: 2)),
                ),
                validator: (value) => value == null || value.isEmpty ? '請輸入城市' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _districtController,
                decoration: InputDecoration(
                  labelText: '地區',
                  hintText: '例如：信義區',
                  prefixIcon: Icon(Icons.place_rounded, color: chinguTheme?.warning ?? Colors.orange),
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: chinguTheme?.surfaceVariant ?? theme.dividerColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: chinguTheme?.surfaceVariant ?? theme.dividerColor)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: chinguTheme?.warning ?? Colors.orange, width: 2)),
                ),
                validator: (value) => value == null || value.isEmpty ? '請輸入地區' : null,
              ),
              const SizedBox(height: 24),
              
              // 備註
              Row(
                children: [
                  Icon(Icons.note_alt_rounded, color: theme.colorScheme.onSurface.withOpacity(0.6), size: 20),
                  const SizedBox(width: 8),
                  Text('備註 (選填)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                maxLength: 100,
                decoration: InputDecoration(
                  hintText: '有什麼想特別說明的嗎？例如：素食友善、喜歡安靜...',
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: chinguTheme?.surfaceVariant ?? theme.dividerColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: chinguTheme?.surfaceVariant ?? theme.dividerColor)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.colorScheme.primary, width: 2)),
                ),
              ),
              const SizedBox(height: 32),
              
              // 創建按鈕
              Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: chinguTheme?.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleCreate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                      : const Text('確認發布', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetChip(String label, int value, ThemeData theme) {
    final chinguTheme = theme.extension<ChinguTheme>();
    final isSelected = _selectedBudget == value;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedBudget = value);
        }
      },
      selectedColor: theme.colorScheme.primary.withOpacity(0.1),
      backgroundColor: theme.cardColor,
      labelStyle: TextStyle(
        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? theme.colorScheme.primary : chinguTheme?.surfaceVariant ?? theme.dividerColor,
      ),
      checkmarkColor: theme.colorScheme.primary,
    );
  }
}
