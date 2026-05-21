import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';

class ProductFormDialog extends StatefulWidget {
  final Product? product; // Jika null, berarti mode Tambah
  final Function(Product) onSave;

  const ProductFormDialog({super.key, this.product, required this.onSave});

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameCtrl;
  late TextEditingController _categoryCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _stockGudangCtrl;
  late TextEditingController _stockDisplayCtrl;
  late TextEditingController _minStockCtrl;
  late TextEditingController _maxStockCtrl;
  late TextEditingController _emojiCtrl;
  late TextEditingController _discountCtrl;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _categoryCtrl = TextEditingController(text: p?.category ?? 'Umum');
    _priceCtrl = TextEditingController(text: p != null ? p.price.toInt().toString() : '');
    _stockGudangCtrl = TextEditingController(text: p?.stockGudang.toString() ?? '0');
    _stockDisplayCtrl = TextEditingController(text: p?.stockDisplay.toString() ?? '0');
    _minStockCtrl = TextEditingController(text: p?.minStock.toString() ?? '5');
    _maxStockCtrl = TextEditingController(text: p?.maxStock.toString() ?? '50');
    _emojiCtrl = TextEditingController(text: p?.emoji ?? '📦');
    _discountCtrl = TextEditingController(text: p?.discountPercent.toString() ?? '0');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _priceCtrl.dispose();
    _stockGudangCtrl.dispose();
    _stockDisplayCtrl.dispose();
    _minStockCtrl.dispose();
    _maxStockCtrl.dispose();
    _emojiCtrl.dispose();
    _discountCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final newProduct = Product(
        id: widget.product?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameCtrl.text,
        category: _categoryCtrl.text,
        price: double.parse(_priceCtrl.text),
        stockGudang: int.parse(_stockGudangCtrl.text),
        stockDisplay: int.parse(_stockDisplayCtrl.text),
        minStock: int.parse(_minStockCtrl.text),
        maxStock: int.parse(_maxStockCtrl.text),
        emoji: _emojiCtrl.text.isEmpty ? '📦' : _emojiCtrl.text,
        discountPercent: double.tryParse(_discountCtrl.text) ?? 0.0,
      );
      widget.onSave(newProduct);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.product != null;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEdit ? 'Edit Produk' : 'Tambah Produk Baru',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(flex: 1, child: _buildTextField('Emoji', _emojiCtrl, maxLength: 2)),
                    const SizedBox(width: 16),
                    Expanded(flex: 3, child: _buildTextField('Nama Produk', _nameCtrl, isRequired: true)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildTextField('Kategori', _categoryCtrl)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField('Harga (Rp)', _priceCtrl, isNumber: true, isRequired: true)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildTextField('Stok Gudang', _stockGudangCtrl, isNumber: true)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField('Stok Display', _stockDisplayCtrl, isNumber: true)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildTextField('Min Stok', _minStockCtrl, isNumber: true)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField('Max Stok', _maxStockCtrl, isNumber: true)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField('Diskon Default (%)', _discountCtrl, isNumber: true),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(isEdit ? 'Simpan Perubahan' : 'Tambah Produk', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false, bool isRequired = false, int? maxLength}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : null,
          maxLength: maxLength,
          validator: isRequired ? (v) => v == null || v.isEmpty ? 'Harus diisi' : null : null,
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            isDense: true,
          ),
        ),
      ],
    );
  }
}
