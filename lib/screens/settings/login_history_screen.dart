import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/models/login_history_model.dart';
import 'package:chingu/widgets/gradient_button.dart';

class LoginHistoryScreen extends StatefulWidget {
  const LoginHistoryScreen({super.key});

  @override
  State<LoginHistoryScreen> createState() => _LoginHistoryScreenState();
}

class _LoginHistoryScreenState extends State<LoginHistoryScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late Future<List<LoginHistoryModel>> _historyFuture;

  @override
  void initState() {
    super.initState();
    final userId = context.read<AuthProvider>().uid;
    if (userId != null) {
      _historyFuture = _firestoreService.getLoginHistory(userId);
    } else {
      _historyFuture = Future.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('登入歷史記錄', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: FutureBuilder<List<LoginHistoryModel>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                  const SizedBox(height: 16),
                  Text('無法載入歷史記錄', style: TextStyle(color: theme.colorScheme.onSurface)),
                  const SizedBox(height: 8),
                  GradientButton(
                    text: '重試',
                    onPressed: () {
                      setState(() {
                        final userId = context.read<AuthProvider>().uid;
                        if (userId != null) {
                          _historyFuture = _firestoreService.getLoginHistory(userId);
                        }
                      });
                    },
                    width: 120,
                  ),
                ],
              ),
            );
          }

          final history = snapshot.data ?? [];
          if (history.isEmpty) {
            return Center(
              child: Text(
                '無登入記錄',
                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: history.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = history[index];
              final isCurrent = index == 0; // Assume first item is current session for mock

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getDeviceIcon(item.deviceModel),
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                item.deviceModel,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (isCurrent) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: theme.colorScheme.primary.withOpacity(0.5)),
                                  ),
                                  child: Text(
                                    '當前',
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item.location} • ${item.ipAddress}',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('yyyy/MM/dd HH:mm').format(item.timestamp),
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(0.4),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getDeviceIcon(String model) {
    final lowerModel = model.toLowerCase();
    if (lowerModel.contains('iphone') || lowerModel.contains('android') || lowerModel.contains('pixel') || lowerModel.contains('samsung')) {
      return Icons.phone_iphone;
    } else if (lowerModel.contains('ipad') || lowerModel.contains('tablet')) {
      return Icons.tablet_mac;
    } else if (lowerModel.contains('mac') || lowerModel.contains('windows') || lowerModel.contains('linux') || lowerModel.contains('pc')) {
      return Icons.computer;
    }
    return Icons.device_unknown;
  }
}
