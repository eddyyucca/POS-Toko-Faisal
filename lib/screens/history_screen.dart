import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppProvider>(context, listen: false).loadTransactionHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final transactions = provider.transactionHistory;
        
        // Calculate totals for today
        final today = DateTime.now();
        int totalTrx = 0;
        double totalIncome = 0;
        
        for (var tx in transactions) {
          DateTime dt = tx['dateObj'];
          if (dt.year == today.year && dt.month == today.month && dt.day == today.day) {
            totalTrx++;
            totalIncome += tx['amount'];
          }
        }

        return Column(
          children: [
            _buildHeader(totalTrx, totalIncome),
            Expanded(child: _buildList(transactions)),
          ],
        );
      },
    );
  }

  Widget _buildHeader(int totalTrx, double totalIncome) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Riwayat Transaksi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                SizedBox(height: 4),
                Text('Seluruh transaksi', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
          _SummaryChip(label: 'Total Transaksi Hari Ini', value: totalTrx.toString(), color: AppColors.primary),
          const SizedBox(width: 12),
          _SummaryChip(label: 'Total Pendapatan Hari Ini', value: _formatPrice(totalIncome), color: AppColors.accent),
          const SizedBox(width: 16),
          OutlinedButton.icon(
            onPressed: () {
              Provider.of<AppProvider>(context, listen: false).loadTransactionHistory();
            },
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Refresh'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> transactions) {
    if (transactions.isEmpty) {
      return const Center(child: Text('Belum ada transaksi.', style: TextStyle(color: AppColors.textSecondary)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: transactions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _TransactionCard(tx: transactions[i]),
    );
  }

  String _formatPrice(double price) {
    final parts = price.toInt().toString().split('').reversed.toList();
    final result = <String>[];
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && i % 3 == 0) result.add('.');
      result.add(parts[i]);
    }
    return 'Rp ${result.reversed.join()}';
  }
}


class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final Map<String, dynamic> tx;

  const _TransactionCard({required this.tx});

  static const Map<String, IconData> _methodIcons = {
    'Tunai': Icons.payments_rounded,
    'QRIS': Icons.qr_code_rounded,
    'Kartu Debit': Icons.credit_card_rounded,
    'Transfer': Icons.account_balance_rounded,
  };

  static const Map<String, Color> _methodColors = {
    'Tunai': AppColors.accent,
    'QRIS': Color(0xFF6366F1),
    'Kartu Debit': AppColors.primary,
    'Transfer': AppColors.warning,
  };

  @override
  Widget build(BuildContext context) {
    final items = tx['items'] as List;
    final method = tx['method'] as String;
    final color = _methodColors[method] ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_methodIcons[method] ?? Icons.payment_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(tx['id'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(width: 10),
                    Text(tx['time'] as String, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(width: 10),
                    Text('• ${tx['cashier']}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(items.join(', '), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatPrice((tx['amount'] as num).toDouble()),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(method, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    final parts = price.toInt().toString().split('').reversed.toList();
    final result = <String>[];
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && i % 3 == 0) result.add('.');
      result.add(parts[i]);
    }
    return 'Rp ${result.reversed.join()}';
  }
}
