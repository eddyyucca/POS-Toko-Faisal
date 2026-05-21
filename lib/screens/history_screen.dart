import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  static final List<Map<String, dynamic>> _transactions = List.generate(18, (i) {
    final items = [
      ['☕ Kopi Arabika x2', '🍳 Nasi Goreng x1'],
      ['🧋 Cappuccino x1', '🍞 Roti Bakar x2'],
      ['🥑 Jus Alpukat x3'],
      ['🍜 Mie Ayam x1', '💧 Air Mineral x2', '🍌 Pisang Goreng x2'],
      ['☕ Kopi Arabika x1', '🥪 Sandwich x1'],
    ];
    final amounts = [98000, 62000, 66000, 71000, 83000];
    final methods = ['Tunai', 'QRIS', 'Kartu Debit', 'Transfer'];
    final hour = 8 + (i * 37 % 10);
    final min = (i * 13) % 60;
    return {
      'id': 'TRX-${(1000 + i).toString()}',
      'time': '${hour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}',
      'items': items[i % items.length],
      'amount': amounts[i % amounts.length],
      'method': methods[i % methods.length],
      'cashier': i % 3 == 0 ? 'Budi' : 'Admin',
    };
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(child: _buildList()),
      ],
    );
  }

  Widget _buildHeader() {
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
                Text('Seluruh transaksi hari ini', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
          _SummaryChip(label: 'Total Transaksi', value: '18', color: AppColors.primary),
          const SizedBox(width: 12),
          _SummaryChip(label: 'Total Pendapatan', value: 'Rp 1.287.000', color: AppColors.accent),
          const SizedBox(width: 16),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.download_rounded, size: 16),
            label: const Text('Export'),
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

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: _transactions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _TransactionCard(tx: _transactions[i]),
    );
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
                _formatPrice((tx['amount'] as int).toDouble()),
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
