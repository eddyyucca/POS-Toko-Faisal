import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_provider.dart';
import '../utils/receipt_generator.dart';

class PaymentDialog extends StatefulWidget {
  final double total;
  final Function(String paymentMethod) onSuccess;

  const PaymentDialog({super.key, required this.total, required this.onSuccess});

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  int _selectedMethod = 0;
  final _cashController = TextEditingController();
  bool _paymentDone = false;

  final List<Map<String, dynamic>> _methods = [
    {'label': 'Tunai', 'icon': Icons.payments_rounded, 'color': const Color(0xFF10B981)},
    {'label': 'QRIS', 'icon': Icons.qr_code_rounded, 'color': const Color(0xFF6366F1)},
    {'label': 'Kartu Debit', 'icon': Icons.credit_card_rounded, 'color': const Color(0xFF2563EB)},
    {'label': 'Transfer', 'icon': Icons.account_balance_rounded, 'color': const Color(0xFFF59E0B)},
  ];

  double get cashAmount => double.tryParse(_cashController.text.replaceAll('.', '')) ?? 0;
  double get change => cashAmount - widget.total;

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  void _printReceipt() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    await ReceiptGenerator.printReceipt(
      items: provider.cartItems,
      subtotal: provider.subtotal,
      totalDiscount: provider.totalDiscount,
      total: provider.total,
      cashAmount: _selectedMethod == 0 ? cashAmount : widget.total,
      change: _selectedMethod == 0 ? change : 0,
      cashier: provider.currentUser,
      paymentMethod: _methods[_selectedMethod]['label'] as String,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(40),
      child: SizedBox(
        width: 480,
        child: _paymentDone ? _buildSuccessView() : _buildPaymentForm(),
      ),
    );
  }

  // ... (keep the rest the same until buildSuccessView) ...
  Widget _buildPaymentForm() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pembayaran',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Tagihan', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                Text(
                  _formatPrice(widget.total),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Metode Pembayaran', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          Row(
            children: List.generate(_methods.length, (i) {
              final m = _methods[i];
              final bool sel = _selectedMethod == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedMethod = i),
                  child: Container(
                    margin: EdgeInsets.only(right: i < _methods.length - 1 ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: sel ? (m['color'] as Color).withValues(alpha: 0.08) : AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: sel ? (m['color'] as Color) : AppColors.border,
                        width: sel ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(m['icon'] as IconData, color: sel ? m['color'] as Color : AppColors.textSecondary, size: 22),
                        const SizedBox(height: 4),
                        Text(
                          m['label'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                            color: sel ? m['color'] as Color : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
          if (_selectedMethod == 0) ...[
            const SizedBox(height: 20),
            const Text('Nominal Uang', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            TextField(
              controller: _cashController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixText: 'Rp ',
                hintText: '0',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [50000, 100000, 50000 + widget.total.toInt(), widget.total.toInt()].map((v) {
                return GestureDetector(
                  onTap: () => setState(() => _cashController.text = v.toString()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(_formatPrice(v.toDouble()), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  ),
                );
              }).toList(),
            ),
            if (_cashController.text.isNotEmpty && cashAmount >= widget.total) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Kembalian', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    Text(
                      _formatPrice(change),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ],
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canPay() ? _processPayment : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.border,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Proses Pembayaran', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          const Text('Pembayaran Berhasil!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(
            'Transaksi ${_formatPrice(widget.total)} selesai',
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          if (_selectedMethod == 0 && change > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_rounded, color: AppColors.warning, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Kembalian: ${_formatPrice(change)}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.warning),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _printReceipt,
                  icon: const Icon(Icons.print_rounded, size: 16),
                  label: const Text('Cetak Struk'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    side: const BorderSide(color: AppColors.border),
                    foregroundColor: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onSuccess(_methods[_selectedMethod]['label'] as String);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: const Text('Transaksi Baru', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _canPay() {
    if (_selectedMethod == 0) return cashAmount >= widget.total;
    return true;
  }

  void _processPayment() {
    setState(() => _paymentDone = true);
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
