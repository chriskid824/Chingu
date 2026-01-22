import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:chingu/services/credit_service.dart';
import 'package:chingu/models/user_credit_model.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/core/theme/app_theme.dart';

class CreditHistoryScreen extends StatefulWidget {
  const CreditHistoryScreen({Key? key}) : super(key: key);

  @override
  State<CreditHistoryScreen> createState() => _CreditHistoryScreenState();
}

class _CreditHistoryScreenState extends State<CreditHistoryScreen> {
  final CreditService _creditService = CreditService();
  UserCreditModel? _userCredit;
  List<CreditTransactionModel> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    if (user == null) return;

    try {
      final credit = await _creditService.getUserCredit(user.uid);
      final history = await _creditService.getTransactionHistory(user.uid);

      if (mounted) {
        setState(() {
          _userCredit = credit;
          _transactions = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('載入失敗: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Scaffold(
      appBar: AppBar(title: const Text('信用積分記錄')),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              _buildHeader(theme, chinguTheme),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _transactions.length,
                  itemBuilder: (context, index) {
                    final item = _transactions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: item.amount >= 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item.amount >= 0 ? Icons.add_circle_outline : Icons.remove_circle_outline,
                            color: item.amount >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                        title: Text(item.description),
                        subtitle: Text(DateFormat('yyyy/MM/dd HH:mm').format(item.createdAt)),
                        trailing: Text(
                          '${item.amount > 0 ? "+" : ""}${item.amount}',
                          style: TextStyle(
                            color: item.amount >= 0 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildHeader(ThemeData theme, ChinguTheme? chinguTheme) {
    if (_userCredit == null) return const SizedBox();

    Color levelColor;
    switch (_userCredit!.level) {
      case CreditLevel.platinum: levelColor = Colors.purple; break;
      case CreditLevel.gold: levelColor = Colors.amber; break;
      case CreditLevel.silver: levelColor = Colors.grey; break;
      default: levelColor = Colors.brown; break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        children: [
          Text(
            '當前積分',
            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
          ),
          const SizedBox(height: 8),
          Text(
            '${_userCredit!.balance}',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: levelColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: levelColor),
            ),
            child: Text(
              _userCredit!.levelText,
              style: TextStyle(
                color: levelColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
