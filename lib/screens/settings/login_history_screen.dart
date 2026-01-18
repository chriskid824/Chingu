import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:chingu/models/login_history_model.dart';
import 'package:chingu/services/login_history_service.dart';
import 'package:chingu/providers/auth_provider.dart';

class LoginHistoryScreen extends StatefulWidget {
  const LoginHistoryScreen({Key? key}) : super(key: key);

  @override
  State<LoginHistoryScreen> createState() => _LoginHistoryScreenState();
}

class _LoginHistoryScreenState extends State<LoginHistoryScreen> {
  final LoginHistoryService _loginHistoryService = LoginHistoryService();
  Stream<List<LoginHistoryModel>>? _historyStream;
  String? _currentUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.uid;

    if (userId != _currentUserId) {
      _currentUserId = userId;
      if (userId != null) {
        _historyStream = _loginHistoryService.getLoginHistory(userId);
      } else {
        _historyStream = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const Scaffold(
        body: Center(child: Text('請先登入')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('登入歷史記錄'),
      ),
      body: StreamBuilder<List<LoginHistoryModel>>(
        stream: _historyStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('發生錯誤: ${snapshot.error}'));
          }

          final history = snapshot.data ?? [];

          if (history.isEmpty) {
            return const Center(child: Text('尚無登入記錄'));
          }

          return ListView.separated(
            itemCount: history.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = history[index];
              return _LoginHistoryItem(item: item);
            },
          );
        },
      ),
    );
  }
}

class _LoginHistoryItem extends StatelessWidget {
  final LoginHistoryModel item;

  const _LoginHistoryItem({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  item.device,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                dateFormat.format(item.timestamp),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  item.location,
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.wifi, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                item.ipAddress,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
