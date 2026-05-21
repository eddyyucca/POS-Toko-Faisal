import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/product.dart';
import '../database/database_helper.dart';
import '../theme/app_theme.dart';

class OpnameScreen extends StatefulWidget {
  const OpnameScreen({super.key});

  @override
  State<OpnameScreen> createState() => _OpnameScreenState();
}

class _OpnameScreenState extends State<OpnameScreen> {
  String _search = '';
  final Map<String, TextEditingController> _gudangControllers = {};
  final Map<String, TextEditingController> _displayControllers = {};

  List<Product> _getFilteredProducts(List<Product> allProducts) {
    return allProducts
        .where((p) => p.name.toLowerCase().contains(_search.toLowerCase()))
        .toList();
  }

  void _initControllers(List<Product> products) {
    for (var p in products) {
      if (!_gudangControllers.containsKey(p.id)) {
        _gudangControllers[p.id] = TextEditingController(text: p.stockGudang.toString());
      }
      if (!_displayControllers.containsKey(p.id)) {
        _displayControllers[p.id] = TextEditingController(text: p.stockDisplay.toString());
      }
    }
  }

  Future<void> _submitOpname(Product product) async {
    final gudangStr = _gudangControllers[product.id]?.text ?? '0';
    final displayStr = _displayControllers[product.id]?.text ?? '0';
    
    final int actualGudang = int.tryParse(gudangStr) ?? product.stockGudang;
    final int actualDisplay = int.tryParse(displayStr) ?? product.stockDisplay;

    final int diffGudang = actualGudang - product.stockGudang;
    final int diffDisplay = actualDisplay - product.stockDisplay;
    final int totalDiff = diffGudang + diffDisplay;

    if (totalDiff == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak ada selisih stok')));
      return;
    }

    final db = await DatabaseHelper.instance.database;
    final provider = Provider.of<AppProvider>(context, listen: false);

    await db.transaction((txn) async {
      await txn.insert('stock_opname', {
        'id': DateTime.now().microsecondsSinceEpoch.toString(),
        'date': DateTime.now().toIso8601String(),
        'productId': product.id,
        'systemGudang': product.stockGudang,
        'systemDisplay': product.stockDisplay,
        'actualGudang': actualGudang,
        'actualDisplay': actualDisplay,
        'difference': totalDiff,
        'notes': 'Stok opname manual',
        'userId': provider.currentUser?.id ?? '0',
      });

      await txn.update(
        'products',
        {
          'stockGudang': actualGudang,
          'stockDisplay': actualDisplay,
        },
        where: 'id = ?',
        whereArgs: [product.id],
      );
    });

    await provider.loadProducts();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stok Opname berhasil dicatat & diperbarui!')));
    }
  }

  @override
  void dispose() {
    for (var c in _gudangControllers.values) { c.dispose(); }
    for (var c in _displayControllers.values) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final products = _getFilteredProducts(provider.products);
        _initControllers(products);

        return Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildTable(products)),
          ],
        );
      },
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
                Text('Stok Opname', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                SizedBox(height: 4),
                Text('Sesuaikan stok fisik dengan stok sistem', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
          SizedBox(
            width: 260,
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Cari produk...',
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(List<Product> products) {
    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          Expanded(
            child: ListView.separated(
              itemCount: products.length,
              separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.border),
              itemBuilder: (_, i) => _buildTableRow(products[i], i + 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: const Row(
        children: [
          Expanded(flex: 3, child: Text('Produk', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
          Expanded(flex: 2, child: Text('Sistem (G / D)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
          Expanded(flex: 2, child: Text('Fisik Gudang', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
          Expanded(flex: 2, child: Text('Fisik Display', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
          SizedBox(width: 100, child: Text('Aksi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
        ],
      ),
    );
  }

  Widget _buildTableRow(Product product, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Text(product.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(child: Text(product.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text('${product.stockGudang} / ${product.stockDisplay}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: TextField(
                controller: _gudangControllers[product.id],
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: TextField(
                controller: _displayControllers[product.id],
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 100,
            child: ElevatedButton(
              onPressed: () => _submitOpname(product),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Simpan', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}
