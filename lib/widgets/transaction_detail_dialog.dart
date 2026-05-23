import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_provider.dart';

class TransactionDetailDialog extends StatefulWidget {
  final Map<String, dynamic> tx;

  const TransactionDetailDialog({super.key, required this.tx});

  @override
  State<TransactionDetailDialog> createState() =>
      _TransactionDetailDialogState();
}

class _TransactionDetailDialogState extends State<TransactionDetailDialog> {
  bool _isVoiding = false;

  // ── helpers ──────────────────────────────────────────────────────────────

  String _formatPrice(double price) {
    final parts = price.toInt().toString().split('').reversed.toList();
    final result = <String>[];
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && i % 3 == 0) result.add('.');
      result.add(parts[i]);
    }
    return 'Rp ${result.reversed.join()}';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}  '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  Color _methodColor(String method) {
    switch (method) {
      case 'QRIS':
        return const Color(0xFF6366F1);
      case 'Kartu Debit':
        return const Color(0xFF2563EB);
      case 'Transfer':
        return const Color(0xFFF59E0B);
      case 'Tunai':
      default:
        return const Color(0xFF10B981);
    }
  }

  IconData _methodIcon(String method) {
    switch (method) {
      case 'QRIS':
        return Icons.qr_code_rounded;
      case 'Kartu Debit':
        return Icons.credit_card_rounded;
      case 'Transfer':
        return Icons.account_balance_rounded;
      case 'Tunai':
      default:
        return Icons.payments_rounded;
    }
  }

  // ── void confirmation dialog ─────────────────────────────────────────────

  Future<void> _showVoidConfirmation(BuildContext context) async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.warning_amber_rounded,
                  color: AppColors.danger, size: 22),
            ),
            const SizedBox(width: 10),
            const Text(
              'Batalkan Transaksi',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.danger.withValues(alpha: 0.2), width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: AppColors.danger, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tindakan ini tidak dapat dibatalkan. Stok produk akan dikembalikan.',
                          style: TextStyle(
                            color: AppColors.danger,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Transaksi: ${widget.tx['id']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total: ${_formatPrice((widget.tx['amount'] as num).toDouble())}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Alasan Pembatalan *',
                    hintText: 'Masukkan alasan pembatalan...',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: AppColors.border, width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: AppColors.border, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: AppColors.primary, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: AppColors.danger, width: 1.5),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Alasan tidak boleh kosong';
                    }
                    if (val.trim().length < 5) {
                      return 'Alasan terlalu singkat (min. 5 karakter)';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Batal'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            icon: const Icon(Icons.delete_forever_rounded, size: 18),
            label: const Text('Ya, Batalkan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isVoiding = true);
      final provider = context.read<AppProvider>();
      final success =
          await provider.voidTransaction(widget.tx['id'], reasonController.text.trim());
      if (!mounted) return;
      setState(() => _isVoiding = false);

      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(
                        'Transaksi ${widget.tx['id']} berhasil dibatalkan')),
              ],
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                    child: Text(
                        'Gagal membatalkan transaksi. Silakan coba lagi.')),
              ],
            ),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tx = widget.tx;
    final provider = context.watch<AppProvider>();
    final currentUser = provider.currentUser;
    final isAdmin = currentUser?.role == 'Admin';

    final String txId = tx['id'] as String;
    final DateTime dateObj = tx['dateObj'] as DateTime;
    final double amount = (tx['amount'] as num).toDouble();
    final double discount = (tx['discount'] as num).toDouble();
    final String cashier = tx['cashier'] as String;
    final String method = tx['method'] as String;
    final String? customerName = tx['customerName'] as String?;
    final List<Map<String, dynamic>> itemDetails =
        (tx['itemDetails'] as List).cast<Map<String, dynamic>>();

    // Compute subtotal from items
    double itemsSubtotal = 0;
    for (final item in itemDetails) {
      final qty = (item['qty'] as num).toDouble();
      final price = (item['price'] as num).toDouble();
      itemsSubtotal += qty * price;
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Container(
        width: 560,
        constraints: const BoxConstraints(maxHeight: 700),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(txId, dateObj, context),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    _buildInfoRow(cashier, method, customerName),
                    const SizedBox(height: 20),
                    _buildItemsTable(itemDetails),
                    const SizedBox(height: 20),
                    _buildSummary(itemsSubtotal, discount, amount),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            _buildActions(context, isAdmin),
          ],
        ),
      ),
    );
  }

  // ── sub-widgets ───────────────────────────────────────────────────────────

  Widget _buildHeader(
      String txId, DateTime dateObj, BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.sidebar,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.receipt_long_rounded,
                color: AppColors.primary, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txId,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 13, color: Colors.white54),
                    const SizedBox(width: 5),
                    Text(
                      _formatDate(dateObj),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Close button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(6),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white60, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      String cashier, String method, String? customerName) {
    final methodColor = _methodColor(method);
    final methodIcon = _methodIcon(method);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          // Kasir
          Expanded(
            child: _infoChip(
              icon: Icons.person_outline_rounded,
              label: 'Kasir',
              value: cashier,
              iconColor: AppColors.primary,
            ),
          ),
          Container(
              width: 1, height: 36, color: AppColors.border),
          // Payment method
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: methodColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        Icon(methodIcon, color: methodColor, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Metode',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: methodColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            method,
                            style: TextStyle(
                              color: methodColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Customer (if any)
          if (customerName != null) ...[
            Container(
                width: 1, height: 36, color: AppColors.border),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: _infoChip(
                  icon: Icons.person_pin_rounded,
                  label: 'Pelanggan',
                  value: customerName,
                  iconColor: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10.5,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemsTable(List<Map<String, dynamic>> itemDetails) {
    const headerStyle = TextStyle(
      color: AppColors.textSecondary,
      fontSize: 11.5,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section label
        Row(
          children: [
            Container(
              width: 3,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Daftar Item',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryLightBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${itemDetails.length} produk',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Table
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Header row
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(11)),
                ),
                child: Row(
                  children: [
                    Expanded(
                        flex: 4,
                        child: Text('PRODUK', style: headerStyle)),
                    SizedBox(
                        width: 40,
                        child: Text('QTY',
                            style: headerStyle,
                            textAlign: TextAlign.center)),
                    Expanded(
                        flex: 3,
                        child: Text('HARGA SATUAN',
                            style: headerStyle,
                            textAlign: TextAlign.right)),
                    Expanded(
                        flex: 3,
                        child: Text('SUBTOTAL',
                            style: headerStyle,
                            textAlign: TextAlign.right)),
                    Expanded(
                        flex: 2,
                        child: Text('DISKON',
                            style: headerStyle,
                            textAlign: TextAlign.right)),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),

              // Item rows
              ...itemDetails.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                final qty = (item['qty'] as num).toDouble();
                final price = (item['price'] as num).toDouble();
                final itemDiscount = (item['discount'] as num).toDouble();
                final subtotalItem = qty * price;
                final discountTotal = qty * itemDiscount;
                final emoji = item['emoji'] as String;
                final name = item['name'] as String;
                final isLast = idx == itemDetails.length - 1;

                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: idx.isEven
                        ? AppColors.surface
                        : AppColors.background.withValues(alpha: 0.5),
                    borderRadius: isLast
                        ? const BorderRadius.vertical(
                            bottom: Radius.circular(11))
                        : null,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Row(
                          children: [
                            const Icon(Icons.inventory_2_rounded, size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 40,
                        child: Text(
                          qty.toInt().toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          _formatPrice(price),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          _formatPrice(subtotalItem),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          discountTotal > 0
                              ? '-${_formatPrice(discountTotal)}'
                              : '-',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: discountTotal > 0
                                ? AppColors.danger
                                : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: discountTotal > 0
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummary(double subtotal, double discount, double total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLightBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          _summaryRow(
            label: 'Subtotal',
            value: _formatPrice(subtotal),
            labelStyle: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
            valueStyle: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (discount > 0) ...[
            const SizedBox(height: 8),
            _summaryRow(
              label: 'Diskon',
              value: '-${_formatPrice(discount)}',
              labelStyle: TextStyle(
                color: AppColors.danger.withValues(alpha: 0.85),
                fontSize: 13,
              ),
              valueStyle: TextStyle(
                color: AppColors.danger,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Divider(color: AppColors.primary.withValues(alpha: 0.2), height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                _formatPrice(total),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow({
    required String label,
    required String value,
    required TextStyle labelStyle,
    required TextStyle valueStyle,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: labelStyle),
        Text(value, style: valueStyle),
      ],
    );
  }

  Widget _buildActions(BuildContext context, bool isAdmin) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(20)),
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          // Print button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.print_rounded,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                              'Cetak struk dari halaman kasir'),
                        ),
                      ],
                    ),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              },
              icon: const Icon(Icons.print_rounded, size: 18),
              label: const Text('Cetak Ulang Struk'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),

          // Void button (admin only)
          if (isAdmin) ...[
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isVoiding
                    ? null
                    : () => _showVoidConfirmation(context),
                icon: _isVoiding
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.danger),
                        ),
                      )
                    : const Icon(Icons.block_rounded, size: 18),
                label: Text(
                    _isVoiding ? 'Memproses...' : 'Batalkan Transaksi (Void)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: BorderSide(color: AppColors.danger, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  disabledForegroundColor:
                      AppColors.danger.withValues(alpha: 0.5),
                  disabledMouseCursor: SystemMouseCursors.wait,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
