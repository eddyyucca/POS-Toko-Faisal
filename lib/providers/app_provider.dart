import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/user.dart';
import '../models/supplier.dart';
import '../models/purchase.dart';
import '../database/database_helper.dart';

class AppProvider with ChangeNotifier {
  User? _currentUser;
  User? get currentUser => _currentUser;

  List<Product> _products = [];
  List<Product> get products => _products;

  final List<CartItem> _cartItems = [];
  List<CartItem> get cartItems => _cartItems;

  double _transactionDiscountPercent = 0.0;
  double _transactionDiscountAmount = 0.0;

  double get transactionDiscountPercent => _transactionDiscountPercent;
  double get transactionDiscountAmount => _transactionDiscountAmount;

  Future<void> loadProducts() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query('products');
    _products = maps.map((e) => Product.fromMap(e)).toList();
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );

    if (maps.isNotEmpty) {
      _currentUser = User.fromMap(maps.first);
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _currentUser = null;
    clearCart();
    notifyListeners();
  }

  // --- Cart Methods ---
  
  void addToCart(Product product) {
    // Cek apakah stok display mencukupi (minimal 1)
    if (product.stockDisplay <= 0) {
      return; // Tidak bisa ditambahkan jika stok display habis
    }

    int index = _cartItems.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      if (_cartItems[index].quantity < product.stockDisplay) {
        _cartItems[index].quantity++;
      }
    } else {
      _cartItems.add(CartItem(product: product));
    }
    notifyListeners();
  }

  void updateCartItemQuantity(Product product, int quantity) {
    int index = _cartItems.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      if (quantity <= 0) {
        _cartItems.removeAt(index);
      } else if (quantity <= product.stockDisplay) {
        _cartItems[index].quantity = quantity;
      }
      notifyListeners();
    }
  }

  void removeCartItem(Product product) {
    _cartItems.removeWhere((item) => item.product.id == product.id);
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    _transactionDiscountPercent = 0.0;
    _transactionDiscountAmount = 0.0;
    notifyListeners();
  }

  double get subtotal {
    return _cartItems.fold(0, (sum, item) => sum + item.subtotal);
  }

  double get totalDiscount {
    double total = subtotal;
    double pct = _transactionDiscountPercent > 0 ? _transactionDiscountPercent : 0.0;
    return (total * (pct / 100)) + _transactionDiscountAmount;
  }

  double get total {
    double finalTotal = subtotal - totalDiscount;
    return finalTotal < 0 ? 0 : finalTotal;
  }

  void setTransactionDiscount({double? percent, double? amount}) {
    if (percent != null) _transactionDiscountPercent = percent;
    if (amount != null) _transactionDiscountAmount = amount;
    notifyListeners();
  }

  // --- Inventory & Checkout Methods ---

  Future<void> processCheckout() async {
    if (_cartItems.isEmpty) return;

    final db = await DatabaseHelper.instance.database;
    final transactionId = DateTime.now().millisecondsSinceEpoch.toString();
    final dateStr = DateTime.now().toIso8601String();
    final String userId = _currentUser?.id ?? '1';

    try {
      await db.transaction((txn) async {
        // 1. Insert Transaction
        await txn.insert('transactions', {
          'id': transactionId,
          'date': dateStr,
          'total': total,
          'discount': totalDiscount,
          'userId': userId,
        });

        // 2. Insert Items & Update Stock
        for (var item in _cartItems) {
          await txn.insert('transaction_items', {
            'id': DateTime.now().microsecondsSinceEpoch.toString(),
            'transactionId': transactionId,
            'productId': item.product.id,
            'qty': item.quantity,
            'price': item.product.price,
            'discount': item.product.price - item.unitPriceAfterDiscount,
          });

          // Kurangi stok display
          int newStockDisplay = item.product.stockDisplay - item.quantity;
          await txn.update(
            'products',
            {'stockDisplay': newStockDisplay},
            where: 'id = ?',
            whereArgs: [item.product.id],
          );
        }
      });

      clearCart();
      await loadProducts(); // Reload products to get latest stock
    } catch (e) {
      debugPrint('Error during checkout: $e');
    }
  }

  Future<void> mutasiStokGudangKeDisplay(String productId, int quantity) async {
    final db = await DatabaseHelper.instance.database;
    
    Product target = _products.firstWhere((p) => p.id == productId);
    if (target.stockGudang >= quantity) {
      int newGudang = target.stockGudang - quantity;
      int newDisplay = target.stockDisplay + quantity;

      await db.update(
        'products',
        {
          'stockGudang': newGudang,
          'stockDisplay': newDisplay,
        },
        where: 'id = ?',
        whereArgs: [productId],
      );

      await loadProducts();
    }
  }

  // --- Product Management (CRUD) ---
  
  Future<void> addProduct(Product product) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('products', product.toMap());
    await loadProducts();
  }

  Future<void> updateProduct(Product product) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
    await loadProducts();
  }

  Future<void> deleteProduct(String productId) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [productId],
    );
    // Hapus dari keranjang jika ada
    _cartItems.removeWhere((item) => item.product.id == productId);
    await loadProducts();
  }

  // --- User Management (CRUD) ---
  
  List<User> _usersList = [];
  List<User> get usersList => _usersList;

  Future<void> loadUsers() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query('users');
    _usersList = maps.map((e) => User.fromMap(e)).toList();
    notifyListeners();
  }

  Future<void> addUser(User user) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('users', user.toMap());
    await loadUsers();
  }

  Future<void> updateUser(User user) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
    await loadUsers();
  }

  Future<void> deleteUser(String userId) async {
    // Jangan hapus diri sendiri
    if (_currentUser?.id == userId) return;
    
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );
    await loadUsers();
  }

  // --- Supplier & Purchase Management ---
  
  List<Supplier> _suppliersList = [];
  List<Supplier> get suppliersList => _suppliersList;

  List<Purchase> _purchasesList = [];
  List<Purchase> get purchasesList => _purchasesList;

  Future<void> loadSuppliers() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query('suppliers');
    _suppliersList = maps.map((e) => Supplier.fromMap(e)).toList();
    notifyListeners();
  }

  Future<void> addSupplier(Supplier supplier) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('suppliers', supplier.toMap());
    await loadSuppliers();
  }

  Future<void> updateSupplier(Supplier supplier) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('suppliers', supplier.toMap(), where: 'id = ?', whereArgs: [supplier.id]);
    await loadSuppliers();
  }

  Future<void> deleteSupplier(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('suppliers', where: 'id = ?', whereArgs: [id]);
    await loadSuppliers();
  }

  Future<void> processPurchase(Purchase purchase, List<PurchaseItem> items) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      // 1. Save Purchase
      await txn.insert('purchases', purchase.toMap());

      // 2. Save Items and Update Stock Gudang
      for (var item in items) {
        await txn.insert('purchase_items', item.toMap());

        // Update Stok Gudang
        Product target = _products.firstWhere((p) => p.id == item.productId);
        int newGudang = target.stockGudang + item.qty;
        await txn.update(
          'products',
          {'stockGudang': newGudang},
          where: 'id = ?',
          whereArgs: [item.productId],
        );
      }
    });

    await loadProducts();
  }

  // --- Transaction History ---
  List<Map<String, dynamic>> _transactionHistory = [];
  List<Map<String, dynamic>> get transactionHistory => _transactionHistory;

  Future<void> loadTransactionHistory() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> txns = await db.rawQuery('''
      SELECT t.id, t.date, t.total, u.username as cashier
      FROM transactions t
      LEFT JOIN users u ON t.userId = u.id
      ORDER BY t.date DESC
    ''');

    List<Map<String, dynamic>> history = [];
    
    for (var tx in txns) {
      final itemsQuery = await db.rawQuery('''
        SELECT ti.qty, p.name, p.emoji
        FROM transaction_items ti
        LEFT JOIN products p ON ti.productId = p.id
        WHERE ti.transactionId = ?
      ''', [tx['id']]);

      List<String> itemsList = [];
      for (var item in itemsQuery) {
        itemsList.add('${item['emoji'] ?? ''} ${item['name'] ?? 'Unknown'} x${item['qty']}');
      }

      DateTime date = DateTime.parse(tx['date'].toString());
      String timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

      history.add({
        'id': tx['id'],
        'time': timeStr,
        'dateObj': date,
        'amount': tx['total'],
        'cashier': tx['cashier'] ?? 'Admin',
        'method': 'Tunai', // Default for now
        'items': itemsList,
      });
    }

    _transactionHistory = history;
    notifyListeners();
  }
}
