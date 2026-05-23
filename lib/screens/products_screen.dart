import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import '../widgets/product_form_dialog.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String _search = '';
  final ScrollController _scrollController = ScrollController();

  // Keys for low-stock rows so we can scroll to them
  final Map<String, GlobalKey> _rowKeys = {};

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<Product> _getFilteredProducts(List<Product> allProducts) {
    return allProducts
        .where((p) => p.name.toLowerCase().contains(_search.toLowerCase()) ||
            p.sku.toLowerCase().contains(_search.toLowerCase()))
        .toList();
  }

  void _showProductForm(BuildContext context, {Product? product}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProductFormDialog(
        product: product,
        onSave: (savedProduct) {
          final provider = Provider.of<AppProvider>(context, listen: false);
          if (product == null) {
            provider.addProduct(savedProduct);
          } else {
            provider.updateProduct(savedProduct);
          }
        },
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text('Anda yakin ingin menghapus "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Provider.of<AppProvider>(context, listen: false)
                  .deleteProduct(product.id);
              Navigator.pop(ctx);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showMutasiDialog(BuildContext context, Product product) {
    final qtyController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Mutasi Stok: ${product.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Stok Gudang: ${product.stockGudang}'),
              Text('Stok Display: ${product.stockDisplay}'),
              const SizedBox(height: 16),
              TextField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah Pindah ke Display',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final qtyStr = qtyController.text;
                if (qtyStr.isNotEmpty) {
                  final qty = int.tryParse(qtyStr) ?? 0;
                  if (qty > 0 && qty <= product.stockGudang) {
                    await Provider.of<AppProvider>(context, listen: false)
                        .mutasiStokGudangKeDisplay(product.id, qty);
                    if (context.mounted) Navigator.pop(ctx);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Jumlah tidak valid atau stok gudang kurang!')),
                    );
                  }
                }
              },
              child: const Text('Pindah'),
            ),
          ],
        );
      },
    );
  }

  /// Scrolls to the first low-stock product in the list.
  void _scrollToFirstLowStock(List<Product> products) {
    for (final p in products) {
      if (p.stockDisplay <= p.minStock) {
        final key = _rowKeys[p.id];
        if (key != null && key.currentContext != null) {
          Scrollable.ensureVisible(
            key.currentContext!,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            alignment: 0.2,
          );
        }
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final products = _getFilteredProducts(provider.products);
        final lowStockProducts =
            products.where((p) => p.stockDisplay <= p.minStock).toList();

        // Rebuild row keys for the current product list
        _rowKeys.clear();
        for (final p in products) {
          _rowKeys[p.id] = GlobalKey();
        }

        return Column(
          children: [
            _buildHeader(context),
            if (lowStockProducts.isNotEmpty)
              _buildLowStockBanner(lowStockProducts, products),
            Expanded(child: _buildTable(products)),
          ],
        );
      },
    );
  }

  Widget _buildLowStockBanner(
      List<Product> lowStockProducts, List<Product> allProducts) {
    return GestureDetector(
      onTap: () => _scrollToFirstLowStock(allProducts),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(24, 12, 24, 0),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  size: 16, color: AppColors.warning),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${lowStockProducts.length} produk dengan stok menipis di display'
                ' — klik untuk melihat',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF7A4F00),
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 13, color: AppColors.warning),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
                Text('Manajemen Produk',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                SizedBox(height: 4),
                Text('Kelola semua produk toko Anda',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
          SizedBox(
            width: 260,
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Cari produk atau SKU...',
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 18, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary)),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                hintStyle: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _showProductForm(context),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Tambah Produk'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
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
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          Expanded(
            child: products.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    controller: _scrollController,
                    itemCount: products.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (_, i) =>
                        _buildTableRow(products[i], i + 1),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inventory_2_outlined,
              size: 48, color: AppColors.border),
          const SizedBox(height: 12),
          Text(
            _search.isEmpty
                ? 'Belum ada produk'
                : 'Produk "$_search" tidak ditemukan',
            style: const TextStyle(
                fontSize: 14, color: AppColors.textSecondary),
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
          SizedBox(
              width: 50,
              child: Text('No.',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary))),
          Expanded(
              flex: 3,
              child: Text('Nama Produk',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary))),
          Expanded(
              flex: 2,
              child: Text('SKU',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary))),
          Expanded(
              flex: 2,
              child: Text('Harga Jual',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary))),
          Expanded(
              flex: 2,
              child: Text('Harga Modal',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary))),
          Expanded(
              flex: 1,
              child: Text('Margin %',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary))),
          Expanded(
              flex: 1,
              child: Text('Gudang',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary))),
          Expanded(
              flex: 1,
              child: Text('Display',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary))),
          Expanded(
              flex: 1,
              child: Text('Min/Max',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary))),
          SizedBox(
              width: 120,
              child: Text('Aksi',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary))),
        ],
      ),
    );
  }

  Widget _buildTableRow(Product product, int index) {
    final bool dangerDisplay = product.stockDisplay == 0;
    final bool warningDisplay =
        !dangerDisplay && product.stockDisplay <= product.minStock;

    final rowKey = _rowKeys[product.id] ?? GlobalKey();

    return Container(
      key: rowKey,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      color: dangerDisplay
          ? AppColors.danger.withValues(alpha: 0.05)
          : warningDisplay
              ? AppColors.warning.withValues(alpha: 0.05)
              : null,
      child: Row(
        children: [
          // No.
          SizedBox(
            width: 50,
            child: Text('$index',
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          ),

          // Nama Produk (with emoji)
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Icon(Icons.inventory_2_rounded, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    product.name,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // SKU
          Expanded(
            flex: 2,
            child: product.sku.isEmpty
                ? const Text('N/A',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary))
                : Text(
                    product.sku,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),

          // Harga Jual
          Expanded(
            flex: 2,
            child: Text(
              _formatPrice(product.price),
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
            ),
          ),

          // Harga Modal
          Expanded(
            flex: 2,
            child: product.costPrice <= 0
                ? const Text('-',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary))
                : Text(
                    _formatPrice(product.costPrice),
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
          ),

          // Margin %
          Expanded(
            flex: 1,
            child: _buildMarginBadge(product),
          ),

          // Gudang
          Expanded(
            flex: 1,
            child: Text(
              '${product.stockGudang}',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),

          // Display
          Expanded(
            flex: 1,
            child: Text(
              '${product.stockDisplay}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: dangerDisplay
                    ? AppColors.danger
                    : warningDisplay
                        ? AppColors.warning
                        : AppColors.primary,
              ),
            ),
          ),

          // Min/Max
          Expanded(
            flex: 1,
            child: Text(
              '${product.minStock}/${product.maxStock}',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ),

          // Aksi
          SizedBox(
            width: 120,
            child: Row(
              children: [
                Tooltip(
                  message: 'Mutasi Stok ke Display',
                  child: _ActionBtn(
                    icon: Icons.move_down_rounded,
                    color: AppColors.primary,
                    onTap: () => _showMutasiDialog(context, product),
                  ),
                ),
                const SizedBox(width: 6),
                Tooltip(
                  message: 'Edit Produk',
                  child: _ActionBtn(
                    icon: Icons.edit_rounded,
                    color: AppColors.primary,
                    onTap: () =>
                        _showProductForm(context, product: product),
                  ),
                ),
                const SizedBox(width: 6),
                Tooltip(
                  message: 'Hapus Produk',
                  child: _ActionBtn(
                    icon: Icons.delete_rounded,
                    color: AppColors.danger,
                    onTap: () =>
                        _showDeleteConfirm(context, product),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarginBadge(Product product) {
    if (product.costPrice <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.border.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(5),
        ),
        child: const Text(
          'N/A',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary),
        ),
      );
    }

    final margin = product.marginPercent;
    final Color badgeColor;
    final Color textColor;

    if (margin > 30) {
      badgeColor = AppColors.primary.withValues(alpha: 0.12);
      textColor = AppColors.primary;
    } else if (margin >= 10) {
      badgeColor = AppColors.warning.withValues(alpha: 0.15);
      textColor = const Color(0xFF7A4F00);
    } else {
      badgeColor = AppColors.danger.withValues(alpha: 0.10);
      textColor = AppColors.danger;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        '${margin.toStringAsFixed(1)}%',
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, color: textColor),
      ),
    );
  }

  String _formatPrice(double price) {
    final parts =
        price.toInt().toString().split('').reversed.toList();
    final result = <String>[];
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && i % 3 == 0) result.add('.');
      result.add(parts[i]);
    }
    return 'Rp ${result.reversed.join()}';
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }
}
