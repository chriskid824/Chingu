import 'package:chingu/models/login_history_model.dart';
import 'package:chingu/services/auth_service.dart';
import 'package:chingu/services/login_history_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LoginHistoryScreen extends StatefulWidget {
  const LoginHistoryScreen({super.key});

  @override
  State<LoginHistoryScreen> createState() => _LoginHistoryScreenState();
}

class _LoginHistoryScreenState extends State<LoginHistoryScreen> {
  final LoginHistoryService _loginHistoryService = LoginHistoryService();
  final AuthService _authService = AuthService();
  late Future<List<LoginHistoryModel>> _historyFuture;

  @override
  void initState() {
    super.initState();
    final user = _authService.currentUser;
    if (user != null) {
      _historyFuture = _loginHistoryService.getLoginHistory(user.uid);
    } else {
      _historyFuture = Future.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('登入歷史'),
      ),
      body: FutureBuilder<List<LoginHistoryModel>>(
        future: _historyFuture,
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
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final item = history[index];
              return ListTile(
                leading: const Icon(Icons.devices),
                title: Text(
                  DateFormat('yyyy/MM/dd HH:mm').format(item.timestamp),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('地點: ${item.location}'),
                    Text('設備: ${item.device}'),
                    if (item.ipAddress.isNotEmpty) Text('IP: ${item.ipAddress}'),
                  ],
                ),
                isThreeLine: true,
              );
            },
          );
        },
      ),
    );
  }
}
