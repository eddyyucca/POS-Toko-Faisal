import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/product.dart';
import '../models/user.dart';
import '../models/supplier.dart';
import '../models/purchase.dart';
import '../models/customer.dart';
import '../database/database_helper.dart';
import '../services/sync_service.dart';

class AppProvider with ChangeNotifier {
  User? _currentUser;
  User? get currentUser => _currentUser;

  List<Product> _products = [];
  List<Product> get products => _products;

  // --- Sync ---
  final SyncService _syncService = SyncService();
  SyncService get syncService => _syncService;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  String _syncStatus = '';
  String get syncStatus => _syncStatus;

  double _syncProgress = 0.0;
  double get syncProgress => _syncProgress;

  int _pendingSyncCount = 0;
  int get pendingSyncCount => _pendingSyncCount;

  DateTime? get lastSyncTime => _syncService.lastSyncTime;
  String? get lastSyncError => _syncService.lastError;

  /// Initialize sync service (call after login)
  Future<void> initSync() async {
    // Load server URL from settings
    final serverUrl = getSetting('sync_server_url', defaultValue: 'https://tokofaisal.fluxatritamaindonesia.com/api');
    _syncService.setServerUrl(serverUrl);
    await _syncService.loadLastSyncTime();
    await updatePendingCount();

    // Set up callbacks
    _syncService.onStatusChanged = (status) {
      _syncStatus = status;
      notifyListeners();
    };
    _syncService.onProgressChanged = (progress) {
      _syncProgress = progress;
      notifyListeners();
    };

    // Auto-sync on startup
    performSync().catchError((_) {});
  }

  /// Update the count of pending sync records
  Future<void> updatePendingCount() async {
    _pendingSyncCount = await _syncService.getTotalPendingCount();
    notifyListeners();
  }

  /// Perform full sync
  Future<SyncResult> performSync() async {
    _isSyncing = true;
    _syncStatus = 'Memulai sinkronisasi...';
    notifyListeners();

    final result = await _syncService.syncAll();

    _isSyncing = false;
    if (result.success) {
      _syncStatus = 'Sinkronisasi berhasil!';
      // Reload data after sync
      await loadProducts();
      await loadCustomers();
      await loadSuppliers();
    } else {
      _syncStatus = result.message;
    }
    await updatePendingCount();
    notifyListeners();

    return result;
  }

  /// Check server connection
  Future<bool> checkSyncConnection() async {
    return await _syncService.checkConnection();
  }

  /// Update sync server URL
  Future<void> setSyncServerUrl(String url) async {
    _syncService.setServerUrl(url);
    await saveSetting('sync_server_url', url);
  }

  final List<CartItem> _cartItems = [];
  List<CartItem> get cartItems => _cartItems;

  double _transactionDiscountPercent = 0.0;
  double _transactionDiscountAmount = 0.0;

  double get transactionDiscountPercent => _transactionDiscountPercent;
  double get transactionDiscountAmount => _transactionDiscountAmount;

  // --- Settings ---
  Map<String, String> _settings = {};
  Map<String, String> get settings => _settings;

  String getSetting(String key, {String defaultValue = ''}) {
    return _settings[key] ?? defaultValue;
  }

  Future<void> loadSettings() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('settings');
    _settings = {for (var row in rows) row['key'] as String: row['value'] as String};
    notifyListeners();
  }

  Future<void> saveSetting(String key, String value) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _settings[key] = value;
    notifyListeners();
  }

  Future<void> saveSettings(Map<String, String> newSettings) async {
    final db = await DatabaseHelper.instance.database;
    final batch = db.batch();
    for (var entry in newSettings.entries) {
      batch.insert(
        'settings',
        {'key': entry.key, 'value': entry.value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    _settings.addAll(newSettings);
    notifyListeners();
  }

  // --- Low Stock ---
  List<Product> get lowStockProducts =>
      _products.where((p) => p.stockDisplay <= p.minStock).toList();

  int get lowStockCount => lowStockProducts.length;

  // --- Products ---
  Future<void> loadProducts() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query('products');
    _products = maps.map((e) => Product.fromMap(e)).toList();
    notifyListeners();
  }

  // --- Auth ---
  Future<bool> login(String username, String password) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );

    if (maps.isNotEmpty) {
      _currentUser = User.fromMap(maps.first);
      await loadSettings();
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _currentUser = null;
    _selectedCustomer = null;
    clearCart();
    notifyListeners();
  }

  // --- Cart Methods ---

  void addToCart(Product product) {
    if (product.stockDisplay <= 0) return;

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
    _selectedCustomer = null;
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

  // --- Selected Customer ---
  Customer? _selectedCustomer;
  Customer? get selectedCustomer => _selectedCustomer;

  void setSelectedCustomer(Customer? customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  // --- Inventory & Checkout Methods ---

  Future<void> processCheckout({String paymentMethod = 'Tunai'}) async {
    if (_cartItems.isEmpty) return;

    final db = await DatabaseHelper.instance.database;
    final randSuffix = Random().nextInt(99999);
    final transactionId = 'TRX-${DateTime.now().millisecondsSinceEpoch}-$randSuffix';
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
          'paymentMethod': paymentMethod,
          'customerId': _selectedCustomer?.id,
          'sync_status': 'pending',
        });

        // 2. Insert Items & Update Stock
        for (var item in _cartItems) {
          await txn.insert('transaction_items', {
            'id': '${DateTime.now().microsecondsSinceEpoch}_${item.product.id}',
            'transactionId': transactionId,
            'productId': item.product.id,
            'qty': item.quantity,
            'price': item.product.price,
            'discount': item.product.price - item.unitPriceAfterDiscount,
            'sync_status': 'pending',
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

        // 3. Update customer points & totalSpend if selected
        if (_selectedCustomer != null) {
          final pointsEarned = (total / double.parse(getSetting('points_per_rupiah', defaultValue: '1000'))).floor();
          await txn.update(
            'customers',
            {
              'points': _selectedCustomer!.points + pointsEarned,
              'totalSpend': _selectedCustomer!.totalSpend + total,
            },
            where: 'id = ?',
            whereArgs: [_selectedCustomer!.id],
          );
        }
      });

      clearCart();
      await loadProducts();
      await loadCustomers();
      await updatePendingCount();

      // Auto-sync after checkout
      performSync().catchError((_) {});
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
    final map = product.toMap();
    map['sync_status'] = 'pending';
    await db.insert('products', map);
    await loadProducts();
  }

  Future<void> updateProduct(Product product) async {
    final db = await DatabaseHelper.instance.database;
    final map = product.toMap();
    map['sync_status'] = 'pending';
    await db.update(
      'products',
      map,
      where: 'id = ?',
      whereArgs: [product.id],
    );
    await loadProducts();
    await updatePendingCount();
  }

  Future<void> deleteProduct(String productId) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [productId],
    );
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

  final List<Purchase> _purchasesList = [];
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
      await txn.insert('purchases', purchase.toMap());

      for (var item in items) {
        await txn.insert('purchase_items', item.toMap());

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

  // --- Customer Management ---

  List<Customer> _customersList = [];
  List<Customer> get customersList => _customersList;

  Future<void> loadCustomers() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query('customers', orderBy: 'name ASC');
    _customersList = maps.map((e) => Customer.fromMap(e)).toList();
    notifyListeners();
  }

  Future<void> addCustomer(Customer customer) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('customers', customer.toMap());
    await loadCustomers();
  }

  Future<void> updateCustomer(Customer customer) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('customers', customer.toMap(), where: 'id = ?', whereArgs: [customer.id]);
    await loadCustomers();
  }

  Future<void> deleteCustomer(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('customers', where: 'id = ?', whereArgs: [id]);
    if (_selectedCustomer?.id == id) _selectedCustomer = null;
    await loadCustomers();
  }

  // --- Transaction History ---
  List<Map<String, dynamic>> _transactionHistory = [];
  List<Map<String, dynamic>> get transactionHistory => _transactionHistory;

  Future<void> loadTransactionHistory() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> txns = await db.rawQuery('''
      SELECT t.id, t.date, t.total, t.discount, t.paymentMethod, t.customerId,
             u.username as cashier, c.name as customerName
      FROM transactions t
      LEFT JOIN users u ON t.userId = u.id
      LEFT JOIN customers c ON t.customerId = c.id
      ORDER BY t.date DESC
    ''');

    List<Map<String, dynamic>> history = [];

    for (var tx in txns) {
      final itemsQuery = await db.rawQuery('''
        SELECT ti.qty, ti.price, ti.discount, p.name, p.emoji
        FROM transaction_items ti
        LEFT JOIN products p ON ti.productId = p.id
        WHERE ti.transactionId = ?
      ''', [tx['id']]);

      List<String> itemsList = [];
      List<Map<String, dynamic>> itemDetails = [];
      for (var item in itemsQuery) {
        itemsList.add('${item['emoji'] ?? ''} ${item['name'] ?? 'Unknown'} x${item['qty']}');
        itemDetails.add({
          'name': item['name'] ?? 'Unknown',
          'emoji': item['emoji'] ?? '📦',
          'qty': item['qty'],
          'price': (item['price'] as num).toDouble(),
          'discount': (item['discount'] as num).toDouble(),
        });
      }

      DateTime date = DateTime.parse(tx['date'].toString());
      String timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

      history.add({
        'id': tx['id'],
        'time': timeStr,
        'dateObj': date,
        'amount': tx['total'],
        'discount': tx['discount'],
        'cashier': tx['cashier'] ?? 'Admin',
        'method': tx['paymentMethod'] ?? 'Tunai',
        'customerName': tx['customerName'],
        'customerId': tx['customerId'],
        'items': itemsList,
        'itemDetails': itemDetails,
      });
    }

    _transactionHistory = history;
    notifyListeners();
  }

  // --- Void Transaction ---
  Future<bool> voidTransaction(String transactionId, String reason) async {
    final db = await DatabaseHelper.instance.database;

    try {
      // Get transaction items
      final items = await db.rawQuery('''
        SELECT ti.productId, ti.qty
        FROM transaction_items ti
        WHERE ti.transactionId = ?
      ''', [transactionId]);

      await db.transaction((txn) async {
        // 1. Record void
        await txn.insert('void_transactions', {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'transactionId': transactionId,
          'date': DateTime.now().toIso8601String(),
          'reason': reason,
          'userId': _currentUser?.id ?? '1',
          'type': 'void',
          'sync_status': 'pending',
        });

        // 2. Return stock
        for (var item in items) {
          final productId = item['productId'] as String;
          final qty = item['qty'] as int;
          await txn.rawUpdate(
            'UPDATE products SET stockDisplay = stockDisplay + ? WHERE id = ?',
            [qty, productId],
          );
        }

        // 3. Delete transaction items and transaction
        await txn.delete('transaction_items', where: 'transactionId = ?', whereArgs: [transactionId]);
        await txn.delete('transactions', where: 'id = ?', whereArgs: [transactionId]);
      });

      await loadProducts();
      await loadTransactionHistory();
      return true;
    } catch (e) {
      debugPrint('Error voiding transaction: $e');
      return false;
    }
  }

  // --- Dashboard Stats ---
  Future<Map<String, dynamic>> getDashboardStats() async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();

    // Today's revenue & transaction count
    final todayStats = await db.rawQuery('''
      SELECT 
        COUNT(*) as count,
        COALESCE(SUM(total), 0) as revenue,
        COALESCE(AVG(total), 0) as avgTransaction
      FROM transactions
      WHERE date BETWEEN ? AND ?
    ''', [todayStart, todayEnd]);

    // Hourly data for today
    final hourlyData = <Map<String, dynamic>>[];
    for (int h = 0; h < 24; h++) {
      final hStart = DateTime(now.year, now.month, now.day, h).toIso8601String();
      final hEnd = DateTime(now.year, now.month, now.day, h, 59, 59).toIso8601String();
      final result = await db.rawQuery('''
        SELECT COALESCE(SUM(total), 0) as revenue, COUNT(*) as count
        FROM transactions WHERE date BETWEEN ? AND ?
      ''', [hStart, hEnd]);
      hourlyData.add({
        'hour': h,
        'revenue': (result.first['revenue'] as num).toDouble(),
        'count': result.first['count'] as int,
      });
    }

    // Top products today
    final topProducts = await db.rawQuery('''
      SELECT p.name, p.emoji, SUM(ti.qty) as totalQty, SUM(ti.qty * ti.price) as totalRevenue
      FROM transaction_items ti
      LEFT JOIN products p ON ti.productId = p.id
      LEFT JOIN transactions t ON ti.transactionId = t.id
      WHERE t.date BETWEEN ? AND ?
      GROUP BY ti.productId
      ORDER BY totalQty DESC
      LIMIT 5
    ''', [todayStart, todayEnd]);

    // Weekly data (last 7 days)
    final weeklyData = <Map<String, dynamic>>[];
    for (int d = 6; d >= 0; d--) {
      final day = now.subtract(Duration(days: d));
      final dayStart = DateTime(day.year, day.month, day.day).toIso8601String();
      final dayEnd = DateTime(day.year, day.month, day.day, 23, 59, 59).toIso8601String();
      final result = await db.rawQuery('''
        SELECT COALESCE(SUM(total), 0) as revenue, COUNT(*) as count
        FROM transactions WHERE date BETWEEN ? AND ?
      ''', [dayStart, dayEnd]);
      weeklyData.add({
        'date': day,
        'revenue': (result.first['revenue'] as num).toDouble(),
        'count': result.first['count'] as int,
      });
    }

    return {
      'todayRevenue': (todayStats.first['revenue'] as num).toDouble(),
      'todayCount': todayStats.first['count'] as int,
      'todayAvg': (todayStats.first['avgTransaction'] as num).toDouble(),
      'hourlyData': hourlyData,
      'topProducts': topProducts,
      'weeklyData': weeklyData,
      'lowStockProducts': lowStockProducts,
    };
  }

  // --- Reports (Real Data) ---
  Future<Map<String, dynamic>> getReportData(String period) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();

    DateTime start;
    DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (period) {
      case 'Hari Ini':
        start = DateTime(now.year, now.month, now.day);
        break;
      case 'Minggu Ini':
        start = now.subtract(Duration(days: now.weekday - 1));
        start = DateTime(start.year, start.month, start.day);
        break;
      case 'Bulan Ini':
        start = DateTime(now.year, now.month, 1);
        break;
      case 'Tahun Ini':
        start = DateTime(now.year, 1, 1);
        break;
      default:
        start = DateTime(now.year, now.month, now.day);
    }

    final startStr = start.toIso8601String();
    final endStr = end.toIso8601String();

    // Summary
    final summary = await db.rawQuery('''
      SELECT 
        COUNT(*) as count,
        COALESCE(SUM(total), 0) as revenue,
        COALESCE(AVG(total), 0) as avgTransaction,
        COALESCE(SUM(discount), 0) as totalDiscount
      FROM transactions
      WHERE date BETWEEN ? AND ?
    ''', [startStr, endStr]);

    // Total items sold
    final itemsSold = await db.rawQuery('''
      SELECT COALESCE(SUM(ti.qty), 0) as totalQty
      FROM transaction_items ti
      LEFT JOIN transactions t ON ti.transactionId = t.id
      WHERE t.date BETWEEN ? AND ?
    ''', [startStr, endStr]);

    // Top products
    final topProducts = await db.rawQuery('''
      SELECT p.name, p.emoji, SUM(ti.qty) as totalQty, 
             SUM(ti.qty * ti.price) as totalRevenue,
             SUM(ti.qty * (ti.price - COALESCE(p.costPrice, 0))) as grossProfit
      FROM transaction_items ti
      LEFT JOIN products p ON ti.productId = p.id
      LEFT JOIN transactions t ON ti.transactionId = t.id
      WHERE t.date BETWEEN ? AND ?
      GROUP BY ti.productId
      ORDER BY totalQty DESC
      LIMIT 5
    ''', [startStr, endStr]);

    // Daily data (last 7 days or within period)
    final dailyData = <Map<String, dynamic>>[];
    const dayNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    for (int d = 6; d >= 0; d--) {
      final day = now.subtract(Duration(days: d));
      final dayStart = DateTime(day.year, day.month, day.day).toIso8601String();
      final dayEnd = DateTime(day.year, day.month, day.day, 23, 59, 59).toIso8601String();
      final result = await db.rawQuery('''
        SELECT COALESCE(SUM(total), 0) as revenue, COUNT(*) as count
        FROM transactions WHERE date BETWEEN ? AND ?
      ''', [dayStart, dayEnd]);
      dailyData.add({
        'day': dayNames[day.weekday - 1],
        'amount': (result.first['revenue'] as num).toDouble(),
        'tx': result.first['count'] as int,
      });
    }

    // Payment methods breakdown
    final paymentBreakdown = await db.rawQuery('''
      SELECT paymentMethod, COUNT(*) as count, COALESCE(SUM(total), 0) as revenue
      FROM transactions
      WHERE date BETWEEN ? AND ?
      GROUP BY paymentMethod
    ''', [startStr, endStr]);

    return {
      'revenue': (summary.first['revenue'] as num).toDouble(),
      'count': summary.first['count'] as int,
      'avgTransaction': (summary.first['avgTransaction'] as num).toDouble(),
      'totalDiscount': (summary.first['totalDiscount'] as num).toDouble(),
      'totalItemsSold': (itemsSold.first['totalQty'] as num).toInt(),
      'topProducts': topProducts,
      'dailyData': dailyData,
      'paymentBreakdown': paymentBreakdown,
    };
  }
}
