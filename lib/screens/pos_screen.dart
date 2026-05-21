import 'package:flutter/material.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import '../widgets/product_card.dart' show ProductListTile;
import '../widgets/cart_panel.dart';
import '../widgets/payment_dialog.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final List<CartItem> _cart = [];
  String _selectedCategory = 'Semua';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  final List<String> _categories = ['Semua', 'Minuman', 'Makanan', 'Snack'];

  List<Product> get _filteredProducts {
    return dummyProducts.where((p) {
      final matchCat = _selectedCategory == 'Semua' || p.category == _selectedCategory;
      final matchSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchCat && matchSearch;
    }).toList();
  }

  void _addToCart(Product product) {
    setState(() {
      final idx = _cart.indexWhere((i) => i.product.id == product.id);
      if (idx >= 0) {
        _cart[idx].quantity++;
      } else {
        _cart.add(CartItem(product: product));
      }
    });
  }

  void _incrementItem(CartItem item) {
    setState(() => item.quantity++);
  }

  void _decrementItem(CartItem item) {
    setState(() {
      if (item.quantity <= 1) {
        _cart.remove(item);
      } else {
        item.quantity--;
      }
    });
  }

  void _removeItem(CartItem item) {
    setState(() => _cart.remove(item));
  }

  void _clearCart() {
    setState(() => _cart.clear());
  }

  void _openPayment() {
    final total = _cart.fold<double>(0, (s, i) => s + i.subtotal) * 1.11;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PaymentDialog(total: total, onSuccess: _clearCart),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildProductArea()),
        CartPanel(
          cartItems: _cart,
          onClearCart: _clearCart,
          onIncrement: _incrementItem,
          onDecrement: _decrementItem,
          onRemove: _removeItem,
          onCheckout: _openPayment,
        ),
      ],
    );
  }

  Widget _buildProductArea() {
    return Column(
      children: [
        _buildTopBar(),
        _buildCategoryTabs(),
        Expanded(child: _buildProductGrid()),
      ],
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: const InputDecoration(
                  hintText: 'Cari produk...',
                  prefixIcon: Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          _buildStatChip(Icons.inventory_2_rounded, '${dummyProducts.length}', 'Produk', AppColors.primary),
          const SizedBox(width: 12),
          _buildStatChip(Icons.receipt_rounded, '24', 'Transaksi', AppColors.accent),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
              Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          ..._categories.map((cat) {
            final bool sel = _selectedCategory == cat;
            final count = cat == 'Semua'
                ? dummyProducts.length
                : dummyProducts.where((p) => p.category == cat).length;
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? AppColors.primary : AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: sel ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      cat,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                        color: sel ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: sel ? Colors.white.withValues(alpha: 0.25) : AppColors.border,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: sel ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    final products = _filteredProducts;
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              'Produk "$_searchQuery" tidak ditemukan',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ListView.builder(
          itemCount: products.length,
          itemBuilder: (_, i) => ProductListTile(
            product: products[i],
            onTap: () => _addToCart(products[i]),
          ),
        ),
      ),
    );
  }
}
