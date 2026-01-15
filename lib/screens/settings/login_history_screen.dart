import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/services/auth_service.dart';
import 'package:chingu/models/login_history_model.dart';

class LoginHistoryScreen extends StatefulWidget {
  const LoginHistoryScreen({super.key});

  @override
  State<LoginHistoryScreen> createState() => _LoginHistoryScreenState();
}

class _LoginHistoryScreenState extends State<LoginHistoryScreen> {
  late Future<List<LoginHistoryModel>> _historyFuture;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    // 使用 addPostFrameCallback 確保 context 可用，或直接在 initState 獲取
    // 這裡直接獲取是因為 initState 中可以訪問 context (但在依賴發生變化時可能需要 didChangeDependencies)
    // 簡單起見，直接從 AuthProvider 獲取當前用戶
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user != null) {
      _historyFuture = _firestoreService.getLoginHistory(user.uid);
    } else {
      _historyFuture = Future.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('登入歷史記錄'),
      ),
      body: FutureBuilder<List<LoginHistoryModel>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('載入失敗: ${snapshot.error}'));
          }

          final history = snapshot.data ?? [];

          if (history.isEmpty) {
            return const Center(child: Text('尚無登入記錄'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: history.length,
            separatorBuilder: (context, index) => const Divider(height: 24),
            itemBuilder: (context, index) {
              final record = history[index];
              return _buildHistoryItem(context, record);
            },
          );
        },
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, LoginHistoryModel record) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.devices, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                record.deviceName,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              dateFormat.format(record.timestamp),
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (record.osVersion.isNotEmpty && record.osVersion != 'Unknown OS')
                _buildInfoRow(context, Icons.system_security_update_good, record.osVersion),
              if (record.location.isNotEmpty && record.location != 'Unknown Location')
                _buildInfoRow(context, Icons.location_on_outlined, record.location),
              if (record.ipAddress.isNotEmpty && record.ipAddress != 'Unknown')
                _buildInfoRow(context, Icons.wifi, record.ipAddress),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurface.withOpacity(0.5)),
          const SizedBox(width: 8),
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }
}
