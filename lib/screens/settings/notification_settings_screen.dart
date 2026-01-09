import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/services/silent_hours_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final _silentHoursService = SilentHoursService();
  bool _isLoading = true;
  
  // Local state for silent hours
  bool _silentHoursEnabled = false;
  late TimeOfDay _silentStart;
  late TimeOfDay _silentEnd;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _silentHoursService.init();
    setState(() {
      _silentHoursEnabled = _silentHoursService.isEnabled;
      _silentStart = _silentHoursService.startTime;
      _silentEnd = _silentHoursService.endTime;
      _isLoading = false;
    });
  }

  Future<void> _updateSilentHoursEnabled(bool value) async {
    setState(() => _silentHoursEnabled = value);
    await _silentHoursService.setEnabled(value);
  }

  Future<void> _pickTime(bool isStart) async {
    final initialTime = isStart ? _silentStart : _silentEnd;
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: theme.cardColor,
              dialHandColor: theme.colorScheme.primary,
              dialBackgroundColor: theme.colorScheme.surfaceVariant,
              hourMinuteColor: WidgetStateColor.resolveWith((states) =>
                states.contains(WidgetState.selected)
                  ? theme.colorScheme.primary.withOpacity(0.2)
                  : theme.cardColor
              ),
              hourMinuteTextColor: WidgetStateColor.resolveWith((states) =>
                states.contains(WidgetState.selected)
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface
              ),
              dayPeriodTextColor: WidgetStateColor.resolveWith((states) =>
                states.contains(WidgetState.selected)
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.6)
              ),
              dayPeriodBorderSide: BorderSide(color: theme.colorScheme.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _silentStart = picked;
        } else {
          _silentEnd = picked;
        }
      });
      await _silentHoursService.setSilentHours(_silentStart, _silentEnd);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('通知設定', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: theme.scaffoldBackgroundColor,
          foregroundColor: theme.colorScheme.onSurface,
          elevation: 0,
        ),
        body: Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('通知設定', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: ListView(
        children: [
          _buildSectionTitle(context, '勿擾模式'),
          SwitchListTile(
            title: const Text('啟用勿擾模式'),
            subtitle: Text('在指定時間內暫停接收通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            value: _silentHoursEnabled,
            onChanged: _updateSilentHoursEnabled,
            activeColor: theme.colorScheme.primary,
          ),
          if (_silentHoursEnabled) ...[
            ListTile(
              title: const Text('開始時間'),
              trailing: Text(
                _silentStart.format(context),
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              onTap: () => _pickTime(true),
            ),
            ListTile(
              title: const Text('結束時間'),
              trailing: Text(
                _silentEnd.format(context),
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              onTap: () => _pickTime(false),
            ),
          ],
          const Divider(),
          _buildSectionTitle(context, '推播通知'),
          SwitchListTile(
            title: const Text('啟用推播通知'),
            subtitle: Text('接收應用程式的推播通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            value: true,
            onChanged: (v) {},
            activeColor: theme.colorScheme.primary,
          ),
          const Divider(),
          _buildSectionTitle(context, '配對通知'),
          SwitchListTile(
            title: const Text('新配對'),
            subtitle: Text('當有人喜歡您時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            value: true,
            onChanged: (v) {},
            activeColor: theme.colorScheme.primary,
          ),
          SwitchListTile(
            title: const Text('配對成功'),
            subtitle: Text('當配對成功時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            value: true,
            onChanged: (v) {},
            activeColor: theme.colorScheme.primary,
          ),
          const Divider(),
          _buildSectionTitle(context, '訊息通知'),
          SwitchListTile(
            title: const Text('新訊息'),
            subtitle: Text('收到新訊息時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            value: true,
            onChanged: (v) {},
            activeColor: theme.colorScheme.primary,
          ),
          SwitchListTile(
            title: const Text('顯示訊息預覽'),
            subtitle: Text('在通知中顯示訊息內容', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            value: false,
            onChanged: (v) {},
            activeColor: theme.colorScheme.primary,
          ),
          const Divider(),
          _buildSectionTitle(context, '活動通知'),
          SwitchListTile(
            title: const Text('預約提醒'),
            subtitle: Text('晚餐前 1 小時提醒', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            value: true,
            onChanged: (v) {},
            activeColor: theme.colorScheme.primary,
          ),
          SwitchListTile(
            title: const Text('預約變更'),
            subtitle: Text('當預約有變更時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            value: true,
            onChanged: (v) {},
            activeColor: theme.colorScheme.primary,
          ),
          const Divider(),
          _buildSectionTitle(context, '行銷通知'),
          SwitchListTile(
            title: const Text('優惠活動'),
            subtitle: Text('接收優惠和活動資訊', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            value: false,
            onChanged: (v) {},
            activeColor: theme.colorScheme.primary,
          ),
          SwitchListTile(
            title: const Text('電子報'),
            subtitle: Text('接收每週電子報', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            value: false,
            onChanged: (v) {},
            activeColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
      ),
    );
  }
}
