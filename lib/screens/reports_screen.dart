import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  int _periodIndex = 0;
  final List<String> _periods = [
    'Hari Ini',
    'Minggu Ini',
    'Bulan Ini',
    'Tahun Ini',
  ];

  bool _isLoading = true;
  Map<String, dynamic> _data = {};

  late AnimationController _barAnimController;
  late Animation<double> _barAnimation;

  @override
  void initState() {
    super.initState();
    _barAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _barAnimation = CurvedAnimation(
      parent: _barAnimController,
      curve: Curves.easeOutCubic,
    );
    _loadData();
  }

  @override
  void dispose() {
    _barAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    _barAnimController.reset();

    try {
      final provider = context.read<AppProvider>();
      final result =
          await provider.getReportData(_periods[_periodIndex]);
      if (!mounted) return;
      setState(() {
        _data = result;
        _isLoading = false;
      });
      _barAnimController.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _changePeriod(int index) {
    if (index == _periodIndex) return;
    setState(() => _periodIndex = index);
    _loadData();
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  String _formatPrice(double price) {
    if (price == 0) return 'Rp 0';
    final parts = price.toInt().toString().split('').reversed.toList();
    final result = <String>[];
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && i % 3 == 0) result.add('.');
      result.add(parts[i]);
    }
    return 'Rp ${result.reversed.join()}';
  }

  String _formatCompact(double value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}M';
    } else if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}jt';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}rb';
    }
    return value.toStringAsFixed(0);
  }

  List<Map<String, dynamic>> get _dailyData {
    final raw = _data['dailyData'];
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(raw as List);
  }

  List<Map<String, dynamic>> get _topProducts {
    final raw = _data['topProducts'];
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(raw as List);
  }

  List<Map<String, dynamic>> get _paymentBreakdown {
    final raw = _data['paymentBreakdown'];
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(raw as List);
  }

  double get _maxDailyAmount {
    if (_dailyData.isEmpty) return 1;
    final max = _dailyData
        .map((d) => (d['amount'] as num).toDouble())
        .reduce((a, b) => a > b ? a : b);
    return max == 0 ? 1 : max;
  }

  double get _revenue => (_data['revenue'] as num?)?.toDouble() ?? 0;
  int get _count => (_data['count'] as num?)?.toInt() ?? 0;
  double get _avgTransaction =>
      (_data['avgTransaction'] as num?)?.toDouble() ?? 0;
  int get _totalItemsSold =>
      (_data['totalItemsSold'] as num?)?.toInt() ?? 0;
  double get _totalDiscount =>
      (_data['totalDiscount'] as num?)?.toDouble() ?? 0;

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(),
          const SizedBox(height: 20),
          if (_isLoading)
            _buildLoadingState()
          else ...[
            _buildSummaryCards(),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth > 900;
                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 6, child: _buildBarChart()),
                      const SizedBox(width: 20),
                      SizedBox(width: 340, child: _buildTopProducts()),
                    ],
                  );
                }
                return Column(
                  children: [
                    _buildBarChart(),
                    const SizedBox(height: 20),
                    _buildTopProducts(),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            _buildPaymentBreakdown(),
          ],
        ],
      ),
    );
  }

  // ─── Page Header ────────────────────────────────────────────────────────────

  Widget _buildPageHeader() {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 16,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Laporan Penjualan',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pantau performa toko Anda · ${_periods[_periodIndex]}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Refresh button
            if (!_isLoading)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: InkWell(
                  onTap: _loadData,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(
                      Icons.refresh_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            // Period tabs
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
                    final bool sel = _periodIndex == i;
                    return GestureDetector(
                      onTap: () => _changePeriod(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: sel
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          _periods[i],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: sel
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: sel
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Loading State ───────────────────────────────────────────────────────────

  Widget _buildLoadingState() {
    return Column(
      children: [
        // Skeleton cards
        Row(
          children: List.generate(4, (i) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < 3 ? 16.0 : 0),
              child: _buildSkeletonCard(),
            ),
          )),
        ),
        const SizedBox(height: 40),
        const CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 3,
        ),
        const SizedBox(height: 12),
        const Text(
          'Memuat data laporan...',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _shimmerBox(40, 40, radius: 10),
              _shimmerBox(60, 24, radius: 6),
            ],
          ),
          const SizedBox(height: 14),
          _shimmerBox(120, 18, radius: 4),
          const SizedBox(height: 6),
          _shimmerBox(80, 12, radius: 4),
        ],
      ),
    );
  }

  Widget _shimmerBox(double w, double h, {double radius = 4}) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  // ─── Summary Cards ───────────────────────────────────────────────────────────

  Widget _buildSummaryCards() {
    final bool hasData = _count > 0;

    final cards = [
      {
        'label': 'Total Pendapatan',
        'value': _formatPrice(_revenue),
        'sub': hasData ? '${_count} transaksi' : 'Belum ada transaksi',
        'icon': Icons.attach_money_rounded,
        'color': AppColors.primary,
        'hasData': hasData,
      },
      {
        'label': 'Total Transaksi',
        'value': '$_count',
        'sub': hasData ? 'Berhasil diproses' : 'Belum ada transaksi',
        'icon': Icons.receipt_long_rounded,
        'color': AppColors.primary,
        'hasData': hasData,
      },
      {
        'label': 'Rata-rata Transaksi',
        'value': _formatPrice(_avgTransaction),
        'sub': hasData ? 'Per transaksi' : 'Belum ada data',
        'icon': Icons.trending_up_rounded,
        'color': AppColors.warning,
        'hasData': hasData,
      },
      {
        'label': 'Produk Terjual',
        'value': '$_totalItemsSold',
        'sub': hasData
            ? 'Diskon: ${_formatPrice(_totalDiscount)}'
            : 'Belum ada penjualan',
        'icon': Icons.inventory_2_rounded,
        'color': const Color(0xFF8B5CF6),
        'hasData': hasData,
      },
    ];

    return Row(
      children: cards.asMap().entries.map((entry) {
        final i = entry.key;
        final c = entry.value;
        final color = c['color'] as Color;
        final bool cardHasData = c['hasData'] as bool;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < cards.length - 1 ? 16.0 : 0),
            child: Container(
              padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
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
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      c['icon'] as IconData,
                      color: color,
                      size: 20,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: cardHasData
                          ? AppColors.primary.withOpacity(0.1)
                          : AppColors.border.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      cardHasData ? 'Ada data' : 'Kosong',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: cardHasData
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  c['value'] as String,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                c['label'] as String,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                c['sub'] as String,
                style: TextStyle(
                  fontSize: 11,
                  color: cardHasData ? color : AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Bar Chart ───────────────────────────────────────────────────────────────

  Widget _buildBarChart() {
    final bool hasData = _dailyData.any(
      (d) => (d['amount'] as num).toDouble() > 0,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Grafik Penjualan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Pendapatan 7 hari terakhir',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              // Legend dot
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryLight],
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Pendapatan',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (!hasData)
            _buildEmptyChart()
          else
            SizedBox(
              height: 220,
              child: AnimatedBuilder(
                animation: _barAnimation,
                builder: (context, _) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: _dailyData.map((d) {
                      final amount =
                          (d['amount'] as num).toDouble();
                      final ratio =
                          (amount / _maxDailyAmount) * _barAnimation.value;
                      final txCount = (d['tx'] as num).toInt();
                      final isToday = _dailyData.last == d;

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Amount label
                              if (amount > 0)
                                Text(
                                  _formatCompact(amount),
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: isToday
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                    fontWeight: isToday
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                  ),
                                  textAlign: TextAlign.center,
                                )
                              else
                                const SizedBox(height: 12),
                              const SizedBox(height: 3),
                              // Bar
                              Stack(
                                alignment: Alignment.bottomCenter,
                                children: [
                                  // Background track
                                  Container(
                                    height: 150,
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  // Filled bar
                                  AnimatedContainer(
                                    duration: Duration.zero,
                                    height: 150 * ratio,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: isToday
                                            ? [
                                                AppColors.primaryDark,
                                                AppColors.primaryLight,
                                              ]
                                            : [
                                                AppColors.primary,
                                                AppColors.primaryLight,
                                              ],
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                      boxShadow: amount > 0
                                          ? [
                                              BoxShadow(
                                                color: AppColors.primary
                                                    .withOpacity(0.25),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Day name
                              Text(
                                d['day'] as String,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isToday
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                  fontWeight: isToday
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                              // Tx count badge
                              if (txCount > 0)
                                Text(
                                  '$txCount tx',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: AppColors.textSecondary,
                                  ),
                                )
                              else
                                const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyChart() {
    return SizedBox(
      height: 200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_rounded,
            size: 48,
            color: AppColors.border,
          ),
          const SizedBox(height: 12),
          const Text(
            'Belum ada data penjualan',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Lakukan transaksi untuk melihat grafik',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Top Products ─────────────────────────────────────────────────────────

  Widget _buildTopProducts() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Produk Terlaris',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Berdasarkan jumlah terjual',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          if (_topProducts.isEmpty)
            _buildEmptyProducts()
          else
            ..._topProducts.asMap().entries.map((e) {
              final i = e.key;
              final p = e.value;
              final String name = p['name']?.toString() ?? 'Produk';
              final String emoji = p['emoji']?.toString() ?? '📦';
              final int qty = (p['totalQty'] as num?)?.toInt() ?? 0;
              final double revenue =
                  (p['totalRevenue'] as num?)?.toDouble() ?? 0;

              // rank colors
              final List<Color> rankColors = [
                const Color(0xFFFFA726), // gold
                const Color(0xFF9E9E9E), // silver
                const Color(0xFF8D6E63), // bronze
                AppColors.textSecondary,
                AppColors.textSecondary,
              ];

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    // Rank badge
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: i < 3
                            ? rankColors[i].withOpacity(0.15)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: rankColors[i],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Emoji
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                            child: const Icon(
                              Icons.inventory_2_rounded,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Name & qty
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '$qty terjual',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Revenue
                    Text(
                      _formatPrice(revenue),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildEmptyProducts() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 40,
              color: AppColors.border,
            ),
            const SizedBox(height: 10),
            const Text(
              'Belum ada produk terjual',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Payment Breakdown ────────────────────────────────────────────────────

  Widget _buildPaymentBreakdown() {
    final Map<String, IconData> methodIcons = {
      'Tunai': Icons.payments_rounded,
      'Transfer': Icons.account_balance_rounded,
      'QRIS': Icons.qr_code_rounded,
      'Debit': Icons.credit_card_rounded,
      'Kartu Kredit': Icons.credit_score_rounded,
    };

    final Map<String, Color> methodColors = {
      'Tunai': AppColors.primary,
      'Transfer': AppColors.primary,
      'QRIS': const Color(0xFF8B5CF6),
      'Debit': AppColors.warning,
      'Kartu Kredit': const Color(0xFFE91E63),
    };

    // Calculate total revenue for percentages
    final double totalRev =
        _paymentBreakdown.fold<double>(
          0,
          (sum, p) => sum + ((p['revenue'] as num?)?.toDouble() ?? 0),
        );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.pie_chart_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Metode Pembayaran',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Rincian per metode',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_paymentBreakdown.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.credit_card_off_rounded,
                      size: 40,
                      color: AppColors.border,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Belum ada data pembayaran',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Row(
              children: _paymentBreakdown.asMap().entries.map((entry) {
                final i = entry.key;
                final p = entry.value;
                final String method =
                    p['paymentMethod']?.toString() ?? 'Lainnya';
                final int count =
                    (p['count'] as num?)?.toInt() ?? 0;
                final double revenue =
                    (p['revenue'] as num?)?.toDouble() ?? 0;
                final double pct =
                    totalRev > 0 ? (revenue / totalRev) * 100 : 0;

                final color =
                    methodColors[method] ?? AppColors.textSecondary;
                final icon =
                    methodIcons[method] ?? Icons.payment_rounded;

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < _paymentBreakdown.length - 1 ? 16.0 : 0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: color.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(icon, color: color, size: 17),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  method,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '$count transaksi',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _formatPrice(revenue),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct / 100,
                          backgroundColor: color.withOpacity(0.1),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(color),
                          minHeight: 5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${pct.toStringAsFixed(1)}% dari total',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
