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
  late TextEditingController _unit2Ctrl;
  late TextEditingController _unit2ConversionCtrl;
  late TextEditingController _unit2PriceCtrl;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _categoryCtrl = TextEditingController(text: p?.category ?? 'Umum');
    _priceCtrl = TextEditingController(
      text: p != null ? _formatRawPrice(p.price) : '',
    );
    _stockGudangCtrl = TextEditingController(
      text: p?.stockGudang.toString() ?? '0',
    );
    _stockDisplayCtrl = TextEditingController(
      text: p?.stockDisplay.toString() ?? '0',
    );
    _minStockCtrl = TextEditingController(text: p?.minStock.toString() ?? '5');
    _maxStockCtrl = TextEditingController(text: p?.maxStock.toString() ?? '50');
    _emojiCtrl = TextEditingController(text: p?.emoji ?? '📦');
    _discountCtrl = TextEditingController(
      text: p?.discountPercent.toString() ?? '0',
    );
    _skuCtrl = TextEditingController(text: p?.sku ?? '');
    _costPriceCtrl = TextEditingController(
      text: p != null ? _formatRawPrice(p.costPrice) : '0',
    );
    _unitCtrl = TextEditingController(text: p?.unit ?? 'Pcs');
    _unit2Ctrl = TextEditingController(text: p?.unit2 ?? '');
    _unit2ConversionCtrl = TextEditingController(
      text: p != null && p.unit2Conversion > 0
          ? p.unit2Conversion.toString()
          : '',
    );
    _unit2PriceCtrl = TextEditingController(
      text: p != null && p.unit2Price > 0 ? _formatRawPrice(p.unit2Price) : '',
    );

    // Listen for price/costPrice changes to rebuild margin indicator
    _priceCtrl.addListener(_onPriceChanged);
    _costPriceCtrl.addListener(_onPriceChanged);
  }

  double _parseFormattedPrice(String text) {
    final clean = text.replaceAll(RegExp(r'[^\d]'), '');
    return double.tryParse(clean) ?? 0.0;
  }

  String _formatRawPrice(double price) {
    if (price <= 0) return '';
    final parts = price.toInt().toString().split('').reversed.toList();
    final result = <String>[];
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && i % 3 == 0) result.add('.');
      result.add(parts[i]);
    }
    return result.reversed.join();
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
    _unit2Ctrl.dispose();
    _unit2ConversionCtrl.dispose();
    _unit2PriceCtrl.dispose();
    super.dispose();
  }

  String? _unit2Error() {
    final hasName = _unit2Ctrl.text.trim().isNotEmpty;
    final hasConversion = _unit2ConversionCtrl.text.trim().isNotEmpty;
    final hasPrice = _unit2PriceCtrl.text.trim().isNotEmpty;
    if (!hasName && !hasConversion && !hasPrice) return null; // satuan besar tidak dipakai

    if (!hasName || !hasConversion || !hasPrice) {
      return 'Nama satuan, isi per satuan, dan harga jual harus diisi semua.';
    }
    final conversion = int.tryParse(_unit2ConversionCtrl.text) ?? 0;
    if (conversion < 1) {
      return 'Isi per satuan minimal 1.';
    }
    return null;
  }

  void _save() async {
    final unit2Error = _unit2Error();
    if (unit2Error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(unit2Error), backgroundColor: AppColors.danger),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      final inputSku = _skuCtrl.text.trim();
      final provider = Provider.of<AppProvider>(context, listen: false);

      // Cek SKU duplikat di local database (hanya untuk produk baru, bukan mode edit)
      if (widget.product == null && inputSku.isNotEmpty) {
        final isSkuExists = provider.products.any(
          (p) => p.sku.trim().toLowerCase() == inputSku.toLowerCase(),
        );

        if (isSkuExists) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal: SKU/Kode Produk "$inputSku" sudah digunakan oleh produk lain!'),
              backgroundColor: AppColors.danger,
            ),
          );
          return;
        }
      }

      final newProduct = Product(
        id:
            widget.product?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameCtrl.text,
        category: _categoryCtrl.text,
        price: _parseFormattedPrice(_priceCtrl.text),
        stockGudang: int.parse(_stockGudangCtrl.text),
        stockDisplay: int.parse(_stockDisplayCtrl.text),
        minStock: int.parse(_minStockCtrl.text),
        maxStock: int.parse(_maxStockCtrl.text),
        emoji: _emojiCtrl.text.isEmpty ? '📦' : _emojiCtrl.text,
        discountPercent: double.tryParse(_discountCtrl.text) ?? 0.0,
        sku: inputSku,
        unit: _unitCtrl.text.isEmpty ? 'Pcs' : _unitCtrl.text,
        costPrice: _parseFormattedPrice(_costPriceCtrl.text),
        unit2: _unit2Ctrl.text.trim(),
        unit2Conversion: int.tryParse(_unit2ConversionCtrl.text) ?? 0,
        unit2Price: _parseFormattedPrice(_unit2PriceCtrl.text),
      );
      widget.onSave(newProduct);
      Navigator.pop(context);
    }
  }

  double? get _currentMargin {
    final price = _parseFormattedPrice(_priceCtrl.text);
    final cost = _parseFormattedPrice(_costPriceCtrl.text);
    if (price > 0 && cost > 0) {
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
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textSecondary,
                      ),
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
                _buildTextField(
                  'Harga Jual (Rp)',
                  _priceCtrl,
                  isNumber: true,
                  isRequired: true,
                  isRupiah: true,
                  customFormatters: [RupiahInputFormatter()],
                ),
                const SizedBox(height: 16),
                // SKU and Cost Price row
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField('SKU / Kode Produk', _skuCtrl),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        'Harga Modal / HPP (Rp)',
                        _costPriceCtrl,
                        isNumber: true,
                        isRupiah: true,
                        customFormatters: [RupiahInputFormatter()],
                      ),
                    ),
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
                    Expanded(
                      child: _buildTextField(
                        'Stok Gudang',
                        _stockGudangCtrl,
                        isNumber: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        'Stok Display',
                        _stockDisplayCtrl,
                        isNumber: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        'Min Stok',
                        _minStockCtrl,
                        isNumber: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        'Max Stok',
                        _maxStockCtrl,
                        isNumber: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  'Diskon Default (%)',
                  _discountCtrl,
                  isNumber: true,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Satuan Besar (Dus/Renteng) - Opsional',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Isi jika barang ini juga dijual per dus/renteng dengan harga berbeda.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildUnit2Field(context)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        'Isi per Satuan (Pcs)',
                        _unit2ConversionCtrl,
                        isNumber: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  'Harga Jual per Satuan Besar (Rp)',
                  _unit2PriceCtrl,
                  isNumber: true,
                  isRupiah: true,
                  customFormatters: [RupiahInputFormatter()],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      isEdit ? 'Simpan Perubahan' : 'Tambah Produk',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
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
    List<TextInputFormatter>? customFormatters,
    bool isRupiah = false,
  }) {
    List<TextInputFormatter>? formatters;
    TextInputType keyboardType = TextInputType.text;

    if (isNumber) {
      keyboardType = isDecimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.number;
      formatters =
          customFormatters ??
          (isDecimal
              ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
              : [FilteringTextInputFormatter.digitsOnly]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: formatters,
          maxLength: maxLength,
          validator: isRequired
              ? (v) => v == null || v.isEmpty ? 'Harus diisi' : null
              : null,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            counterText: '',
            prefixIcon: isRupiah
                ? const Padding(
                    padding: EdgeInsets.only(left: 14, right: 8),
                    child: Text(
                      'Rp',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  )
                : null,
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryField(BuildContext context) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final categories = provider.products
        .map((p) => p.category)
        .toSet()
        .toList();

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
                hintStyle: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
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
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
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
          },
        ),
      ],
    );
  }

  Widget _buildUnitField(BuildContext context) {
    final units = [
      'Pcs',
      'Kg',
      'Gram',
      'Liter',
      'Box',
      'Karton',
      'Lusin',
      'Pack',
    ];
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
                hintStyle: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
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
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
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
          },
        ),
      ],
    );
  }

  Widget _buildUnit2Field(BuildContext context) {
    final units = ['Dus', 'Renteng', 'Box', 'Karton', 'Lusin', 'Pack'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nama Satuan Besar',
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
              controller: _unit2Ctrl,
              enableFilter: true,
              enableSearch: true,
              requestFocusOnTap: true,
              hintText: 'Mis. Dus / Renteng',
              textStyle: const TextStyle(fontSize: 14),
              inputDecorationTheme: InputDecorationTheme(
                hintStyle: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
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
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                filled: true,
                fillColor: AppColors.background,
              ),
              dropdownMenuEntries: units.map((String u) {
                return DropdownMenuEntry<String>(value: u, label: u);
              }).toList(),
              onSelected: (String? selection) {
                if (selection != null) {
                  _unit2Ctrl.text = selection;
                }
              },
            );
          },
        ),
      ],
    );
  }
}

class RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    final String cleanText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanText.isEmpty) {
      return newValue.copyWith(
        text: '',
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

    final double value = double.parse(cleanText);

    final parts = value.toInt().toString().split('').reversed.toList();
    final result = <String>[];
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && i % 3 == 0) result.add('.');
      result.add(parts[i]);
    }
    final String formattedText = result.reversed.join();

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}
