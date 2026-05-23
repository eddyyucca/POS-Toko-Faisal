import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

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
  late TextEditingController _skuCtrl;
  late TextEditingController _costPriceCtrl;
  late TextEditingController _unitCtrl;

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
    _skuCtrl = TextEditingController(text: p?.sku ?? '');
    _costPriceCtrl = TextEditingController(text: p != null ? p.costPrice.toInt().toString() : '0');
    _unitCtrl = TextEditingController(text: p?.unit ?? 'Pcs');

    // Listen for price/costPrice changes to rebuild margin indicator
    _priceCtrl.addListener(_onPriceChanged);
    _costPriceCtrl.addListener(_onPriceChanged);
  }

  void _onPriceChanged() {
    setState(() {});
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
    _skuCtrl.dispose();
    _costPriceCtrl.dispose();
    _unitCtrl.dispose();
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
        sku: _skuCtrl.text,
        unit: _unitCtrl.text.isEmpty ? 'Pcs' : _unitCtrl.text,
        costPrice: double.tryParse(_costPriceCtrl.text) ?? 0.0,
      );
      widget.onSave(newProduct);
      Navigator.pop(context);
    }
  }

  double? get _currentMargin {
    final price = double.tryParse(_priceCtrl.text);
    final cost = double.tryParse(_costPriceCtrl.text);
    if (price != null && cost != null && price > 0 && cost > 0) {
      return (price - cost) / price * 100;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.product != null;
    final margin = _currentMargin;

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
                _buildTextField('Nama Produk', _nameCtrl, isRequired: true),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildCategoryField(context)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildUnitField(context)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField('Harga Jual (Rp)', _priceCtrl, isNumber: true, isRequired: true),
                const SizedBox(height: 16),
                // SKU and Cost Price row
                Row(
                  children: [
                    Expanded(child: _buildTextField('SKU / Kode Produk', _skuCtrl)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField('Harga Modal / HPP (Rp)', _costPriceCtrl, isNumber: true, isDecimal: true)),
                  ],
                ),
                // Margin indicator
                if (margin != null) ...[
                  const SizedBox(height: 10),
                  _buildMarginIndicator(margin),
                ],
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

  Widget _buildMarginIndicator(double margin) {
    final Color indicatorColor;
    final String label;
    final IconData icon;

    if (margin > 30) {
      indicatorColor = AppColors.primary;
      label = 'Margin bagus';
      icon = Icons.trending_up_rounded;
    } else if (margin >= 10) {
      indicatorColor = AppColors.warning;
      label = 'Margin sedang';
      icon = Icons.trending_flat_rounded;
    } else {
      indicatorColor = AppColors.danger;
      label = 'Margin rendah';
      icon = Icons.trending_down_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: indicatorColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: indicatorColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: indicatorColor, size: 18),
          const SizedBox(width: 8),
          Text(
            'Margin: ',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            '${margin.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: indicatorColor,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '($label)',
            style: TextStyle(
              fontSize: 12,
              color: indicatorColor.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
    bool isDecimal = false,
    bool isRequired = false,
    int? maxLength,
  }) {
    List<TextInputFormatter>? formatters;
    TextInputType keyboardType = TextInputType.text;

    if (isNumber) {
      keyboardType = isDecimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.number;
      formatters = isDecimal
          ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
          : [FilteringTextInputFormatter.digitsOnly];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: formatters,
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
  Widget _buildCategoryField(BuildContext context) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final categories = provider.products.map((p) => p.category).toSet().toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kategori',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            return DropdownMenu<String>(
              width: constraints.maxWidth,
              controller: _categoryCtrl,
              enableFilter: true,
              enableSearch: true,
              requestFocusOnTap: true,
              hintText: 'Pilih / Ketik Kategori',
              textStyle: const TextStyle(fontSize: 14),
              inputDecorationTheme: InputDecorationTheme(
                hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
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
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                filled: true,
                fillColor: AppColors.background,
              ),
              dropdownMenuEntries: categories.map((String cat) {
                return DropdownMenuEntry<String>(value: cat, label: cat);
              }).toList(),
              onSelected: (String? selection) {
                if (selection != null) {
                  _categoryCtrl.text = selection;
                }
              },
            );
          }
        ),
      ],
    );
  }

  Widget _buildUnitField(BuildContext context) {
    final units = ['Pcs', 'Kg', 'Gram', 'Liter', 'Box', 'Karton', 'Lusin', 'Pack'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Satuan (Unit)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            return DropdownMenu<String>(
              width: constraints.maxWidth,
              controller: _unitCtrl,
              enableFilter: true,
              enableSearch: true,
              requestFocusOnTap: true,
              hintText: 'Pilih / Ketik Satuan',
              textStyle: const TextStyle(fontSize: 14),
              inputDecorationTheme: InputDecorationTheme(
                hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
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
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                filled: true,
                fillColor: AppColors.background,
              ),
              dropdownMenuEntries: units.map((String u) {
                return DropdownMenuEntry<String>(value: u, label: u);
              }).toList(),
              onSelected: (String? selection) {
                if (selection != null) {
                  _unitCtrl.text = selection;
                }
              },
            );
          }
        ),
      ],
    );
  }
}
