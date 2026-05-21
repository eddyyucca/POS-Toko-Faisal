import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _period = 0;
  final List<String> _periods = ['Hari Ini', 'Minggu Ini', 'Bulan Ini', 'Tahun Ini'];

  final List<Map<String, dynamic>> _dailyData = [
    {'day': 'Sen', 'amount': 1250000, 'tx': 18},
    {'day': 'Sel', 'amount': 980000, 'tx': 14},
    {'day': 'Rab', 'amount': 1560000, 'tx': 22},
    {'day': 'Kam', 'amount': 2100000, 'tx': 31},
    {'day': 'Jum', 'amount': 1890000, 'tx': 27},
    {'day': 'Sab', 'amount': 2800000, 'tx': 42},
    {'day': 'Min', 'amount': 3200000, 'tx': 48},
  ];

  final List<Map<String, dynamic>> _topProducts = [
    {'name': 'Kopi Arabika', 'emoji': '☕', 'qty': 142, 'revenue': 3550000},
    {'name': 'Nasi Goreng', 'emoji': '🍳', 'qty': 98, 'revenue': 3430000},
    {'name': 'Cappuccino', 'emoji': '🧋', 'qty': 87, 'revenue': 2610000},
    {'name': 'Mie Ayam', 'emoji': '🍜', 'qty': 76, 'revenue': 2128000},
    {'name': 'Jus Alpukat', 'emoji': '🥑', 'qty': 64, 'revenue': 1408000},
  ];

  double get maxAmount => _dailyData.map((d) => d['amount'] as int).reduce((a, b) => a > b ? a : b).toDouble();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(),
          const SizedBox(height: 20),
          _buildSummaryCards(),
          const SizedBox(height: 20),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              SizedBox(
                width: 600,
                child: _buildBarChart(),
              ),
              SizedBox(
                width: 350,
                child: _buildTopProducts(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader() {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 16,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Laporan Penjualan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            SizedBox(height: 4),
            Text('Pantau performa toko Anda', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_periods.length, (i) {
                final bool sel = _period == i;
                return GestureDetector(
                  onTap: () => setState(() => _period = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      _periods[i],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                        color: sel ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    final cards = [
      {'label': 'Total Pendapatan', 'value': 'Rp 13.780.000', 'change': '+12.4%', 'up': true, 'icon': Icons.attach_money_rounded, 'color': AppColors.primary},
      {'label': 'Total Transaksi', 'value': '202', 'change': '+8.7%', 'up': true, 'icon': Icons.receipt_rounded, 'color': AppColors.accent},
      {'label': 'Rata-rata Transaksi', 'value': 'Rp 68.200', 'change': '+3.2%', 'up': true, 'icon': Icons.trending_up_rounded, 'color': AppColors.warning},
      {'label': 'Produk Terjual', 'value': '547', 'change': '-2.1%', 'up': false, 'icon': Icons.inventory_rounded, 'color': const Color(0xFF8B5CF6)},
    ];
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: cards.map((c) {
        final color = c['color'] as Color;
        return Container(
          width: 240,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
            boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(c['icon'] as IconData, color: color, size: 20),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (c['up'] as bool) ? AppColors.accent.withOpacity(0.1) : AppColors.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      c['change'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: (c['up'] as bool) ? AppColors.accent : AppColors.danger,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(c['value'] as String, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              ),
              const SizedBox(height: 4),
              Text(c['label'] as String, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBarChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Penjualan Mingguan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          const Text('Pendapatan 7 hari terakhir', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _dailyData.map((d) {
                final ratio = (d['amount'] as int) / maxAmount;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${((d['amount'] as int) / 1000000).toStringAsFixed(1)}jt',
                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          height: 140 * ratio,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.primaryLight],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(d['day'] as String, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProducts() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Produk Terlaris', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          const Text('Berdasarkan jumlah terjual', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ..._topProducts.asMap().entries.map((e) {
            final i = e.key;
            final p = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: i == 0 ? AppColors.warning.withValues(alpha: 0.15) : AppColors.background,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: i == 0 ? AppColors.warning : AppColors.textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p['name'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                        Text('${p['qty']} terjual', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Text(
                    _formatPrice((p['revenue'] as int).toDouble()),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ],
              ),
            );
          }),
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
