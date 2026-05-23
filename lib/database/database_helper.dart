import 'dart:io';
import 'dart:math' as math;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pos_database.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // Initialize FFI for desktop
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getApplicationSupportDirectory();
    final path = join(dbPath.path, filePath);

    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 7,
        onCreate: _createDB,
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 5) {
            // Full reset for versions before 5
            await db.execute('DROP TABLE IF EXISTS users');
            await db.execute('DROP TABLE IF EXISTS products');
            await db.execute('DROP TABLE IF EXISTS transactions');
            await db.execute('DROP TABLE IF EXISTS transaction_items');
            await db.execute('DROP TABLE IF EXISTS stock_opname');
            await db.execute('DROP TABLE IF EXISTS suppliers');
            await db.execute('DROP TABLE IF EXISTS purchases');
            await db.execute('DROP TABLE IF EXISTS purchase_items');
            await db.execute('DROP TABLE IF EXISTS settings');
            await db.execute('DROP TABLE IF EXISTS customers');
            await db.execute('DROP TABLE IF EXISTS void_transactions');
            await _createDB(db, newVersion);
          }
          if (oldVersion < 6) {
            // Add sync_status column to all tables for sync tracking
            final tables = [
              'users', 'products', 'transactions', 'transaction_items',
              'stock_opname', 'suppliers', 'purchases', 'purchase_items',
              'customers', 'void_transactions',
            ];
            for (final table in tables) {
              try {
                await db.execute(
                  "ALTER TABLE $table ADD COLUMN sync_status TEXT DEFAULT 'synced'"
                );
              } catch (_) {
                // Column might already exist
              }
            }
          }
          if (oldVersion < 7) {
            try {
              await db.execute(
                "ALTER TABLE products ADD COLUMN unit TEXT DEFAULT 'Pcs'"
              );
            } catch (_) {}
          }
        },

      ),
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    await db.execute('''
      CREATE TABLE users (
        id $idType,
        username $textType,
        password $textType,
        role $textType,
        sync_status TEXT DEFAULT 'synced'
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id $idType,
        name $textType,
        category $textType,
        price $realType,
        costPrice REAL NOT NULL DEFAULT 0.0,
        stockGudang $integerType,
        stockDisplay $integerType,
        minStock $integerType,
        maxStock $integerType,
        emoji $textType,
        discountPercent $realType,
        sku TEXT DEFAULT "",
        unit TEXT DEFAULT 'Pcs',
        sync_status TEXT DEFAULT 'synced'
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id $idType,
        date $textType,
        total $realType,
        discount $realType,
        userId $textType,
        paymentMethod TEXT DEFAULT "Tunai",
        customerId TEXT,
        sync_status TEXT DEFAULT 'synced'
      )
    ''');

    await db.execute('''
      CREATE TABLE transaction_items (
        id $idType,
        transactionId $textType,
        productId $textType,
        qty $integerType,
        price $realType,
        discount $realType,
        sync_status TEXT DEFAULT 'synced'
      )
    ''');

    await db.execute('''
      CREATE TABLE stock_opname (
        id $idType,
        date $textType,
        productId $textType,
        systemGudang $integerType,
        systemDisplay $integerType,
        actualGudang $integerType,
        actualDisplay $integerType,
        difference $integerType,
        notes TEXT,
        userId $textType,
        sync_status TEXT DEFAULT 'synced'
      )
    ''');

    await db.execute('''
      CREATE TABLE suppliers (
        id $idType,
        name $textType,
        phone $textType,
        address $textType,
        sync_status TEXT DEFAULT 'synced'
      )
    ''');

    await db.execute('''
      CREATE TABLE purchases (
        id $idType,
        date $textType,
        supplierId $textType,
        total $realType,
        notes TEXT,
        userId $textType,
        sync_status TEXT DEFAULT 'synced'
      )
    ''');

    await db.execute('''
      CREATE TABLE purchase_items (
        id $idType,
        purchaseId $textType,
        productId $textType,
        qty $integerType,
        costPrice $realType,
        sync_status TEXT DEFAULT 'synced'
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE customers (
        id $idType,
        name $textType,
        phone $textType,
        email TEXT DEFAULT "",
        points INTEGER NOT NULL DEFAULT 0,
        totalSpend REAL NOT NULL DEFAULT 0.0,
        createdAt $textType,
        sync_status TEXT DEFAULT 'synced'
      )
    ''');

    await db.execute('''
      CREATE TABLE void_transactions (
        id $idType,
        transactionId $textType,
        date $textType,
        reason $textType,
        userId $textType,
        type $textType,
        sync_status TEXT DEFAULT 'synced'
      )
    ''');

    // Insert Default User (admin/admin)
    await db.insert('users', {
      'id': '1',
      'username': 'admin',
      'password': 'admin',
      'role': 'Admin',
    });

    // Insert Default Settings
    await _insertDefaultSettings(db);

    // Minimarket & PPOB Dummy Data
    final dummyProducts = [
      // PPOB
      {'id': 'P-001', 'name': 'Pulsa Telkomsel 10.000', 'category': 'PPOB', 'price': 12000.0, 'costPrice': 10500.0, 'stockGudang': 999, 'stockDisplay': 999, 'minStock': 10, 'maxStock': 1000, 'emoji': '', 'discountPercent': 0.0, 'sku': 'PLS-TSEL-10K'},
      {'id': 'P-002', 'name': 'Pulsa Telkomsel 20.000', 'category': 'PPOB', 'price': 22000.0, 'costPrice': 20500.0, 'stockGudang': 999, 'stockDisplay': 999, 'minStock': 10, 'maxStock': 1000, 'emoji': '', 'discountPercent': 0.0, 'sku': 'PLS-TSEL-20K'},
      {'id': 'P-003', 'name': 'Pulsa Indosat 25.000', 'category': 'PPOB', 'price': 27000.0, 'costPrice': 25500.0, 'stockGudang': 999, 'stockDisplay': 999, 'minStock': 10, 'maxStock': 1000, 'emoji': '', 'discountPercent': 0.0, 'sku': 'PLS-IND-25K'},
      {'id': 'P-004', 'name': 'Token PLN 20.000', 'category': 'PPOB', 'price': 22500.0, 'costPrice': 20500.0, 'stockGudang': 999, 'stockDisplay': 999, 'minStock': 10, 'maxStock': 1000, 'emoji': '', 'discountPercent': 0.0, 'sku': 'PLN-20K'},
      {'id': 'P-005', 'name': 'Token PLN 50.000', 'category': 'PPOB', 'price': 52500.0, 'costPrice': 50500.0, 'stockGudang': 999, 'stockDisplay': 999, 'minStock': 10, 'maxStock': 1000, 'emoji': '', 'discountPercent': 0.0, 'sku': 'PLN-50K'},
      {'id': 'P-006', 'name': 'Top Up DANA 50.000', 'category': 'E-Wallet', 'price': 51500.0, 'costPrice': 50000.0, 'stockGudang': 999, 'stockDisplay': 999, 'minStock': 10, 'maxStock': 1000, 'emoji': '', 'discountPercent': 0.0, 'sku': 'DANA-50K'},
      {'id': 'P-007', 'name': 'Top Up OVO 100.000', 'category': 'E-Wallet', 'price': 102000.0, 'costPrice': 100000.0, 'stockGudang': 999, 'stockDisplay': 999, 'minStock': 10, 'maxStock': 1000, 'emoji': '', 'discountPercent': 0.0, 'sku': 'OVO-100K'},
      // Makanan Ringan
      {'id': 'S-001', 'name': 'Chitato Sapi Panggang 68g', 'category': 'Cemilan', 'price': 11500.0, 'costPrice': 9500.0, 'stockGudang': 120, 'stockDisplay': 20, 'minStock': 10, 'maxStock': 100, 'emoji': '', 'discountPercent': 0.0, 'sku': 'SNK-001'},
      {'id': 'S-002', 'name': 'Taro Net Seaweed 65g', 'category': 'Cemilan', 'price': 9000.0, 'costPrice': 7000.0, 'stockGudang': 100, 'stockDisplay': 15, 'minStock': 10, 'maxStock': 100, 'emoji': '', 'discountPercent': 0.0, 'sku': 'SNK-002'},
      {'id': 'S-003', 'name': 'Beng Beng Chocolate', 'category': 'Cemilan', 'price': 3000.0, 'costPrice': 2000.0, 'stockGudang': 200, 'stockDisplay': 40, 'minStock': 20, 'maxStock': 150, 'emoji': '', 'discountPercent': 0.0, 'sku': 'SNK-003'},
      {'id': 'S-004', 'name': 'Silverqueen Cashew 62g', 'category': 'Cemilan', 'price': 16500.0, 'costPrice': 13000.0, 'stockGudang': 80, 'stockDisplay': 10, 'minStock': 5, 'maxStock': 50, 'emoji': '', 'discountPercent': 5.0, 'sku': 'SNK-004'},
      {'id': 'S-005', 'name': 'Roma Kelapa 300g', 'category': 'Cemilan', 'price': 12500.0, 'costPrice': 10000.0, 'stockGudang': 50, 'stockDisplay': 10, 'minStock': 5, 'maxStock': 40, 'emoji': '', 'discountPercent': 0.0, 'sku': 'SNK-005'},
      // Minuman
      {'id': 'M-001', 'name': 'Aqua Botol 600ml', 'category': 'Minuman', 'price': 3500.0, 'costPrice': 2500.0, 'stockGudang': 300, 'stockDisplay': 50, 'minStock': 24, 'maxStock': 200, 'emoji': '', 'discountPercent': 0.0, 'sku': 'MNM-001'},
      {'id': 'M-002', 'name': 'Pocari Sweat 500ml', 'category': 'Minuman', 'price': 7500.0, 'costPrice': 6000.0, 'stockGudang': 150, 'stockDisplay': 30, 'minStock': 12, 'maxStock': 100, 'emoji': '', 'discountPercent': 0.0, 'sku': 'MNM-002'},
      {'id': 'M-003', 'name': 'Teh Pucuk Harum 350ml', 'category': 'Minuman', 'price': 4000.0, 'costPrice': 3000.0, 'stockGudang': 200, 'stockDisplay': 40, 'minStock': 24, 'maxStock': 150, 'emoji': '', 'discountPercent': 0.0, 'sku': 'MNM-003'},
      {'id': 'M-004', 'name': 'Kopi Kenangan Mantancino', 'category': 'Minuman', 'price': 9500.0, 'costPrice': 8000.0, 'stockGudang': 60, 'stockDisplay': 15, 'minStock': 10, 'maxStock': 50, 'emoji': '', 'discountPercent': 0.0, 'sku': 'MNM-004'},
      {'id': 'M-005', 'name': 'Susu Bear Brand 189ml', 'category': 'Minuman', 'price': 10500.0, 'costPrice': 9000.0, 'stockGudang': 100, 'stockDisplay': 25, 'minStock': 15, 'maxStock': 80, 'emoji': '', 'discountPercent': 0.0, 'sku': 'MNM-005'},
      // Sembako
      {'id': 'B-001', 'name': 'Beras Maknyus 5Kg', 'category': 'Sembako', 'price': 72000.0, 'costPrice': 65000.0, 'stockGudang': 50, 'stockDisplay': 5, 'minStock': 5, 'maxStock': 30, 'emoji': '', 'discountPercent': 0.0, 'sku': 'SMK-001'},
      {'id': 'B-002', 'name': 'Minyak Goreng Bimoli 2L', 'category': 'Sembako', 'price': 36500.0, 'costPrice': 33000.0, 'stockGudang': 60, 'stockDisplay': 10, 'minStock': 6, 'maxStock': 40, 'emoji': '', 'discountPercent': 0.0, 'sku': 'SMK-002'},
      {'id': 'B-003', 'name': 'Gula Pasir Gulaku 1Kg', 'category': 'Sembako', 'price': 16000.0, 'costPrice': 14500.0, 'stockGudang': 100, 'stockDisplay': 15, 'minStock': 10, 'maxStock': 50, 'emoji': '', 'discountPercent': 0.0, 'sku': 'SMK-003'},
      {'id': 'B-004', 'name': 'Indomie Kaldu Ayam', 'category': 'Sembako', 'price': 3000.0, 'costPrice': 2500.0, 'stockGudang': 400, 'stockDisplay': 50, 'minStock': 40, 'maxStock': 200, 'emoji': '', 'discountPercent': 0.0, 'sku': 'SMK-004'},
      {'id': 'B-005', 'name': 'Telur Ayam Negeri (1 Kg)', 'category': 'Sembako', 'price': 28000.0, 'costPrice': 25000.0, 'stockGudang': 30, 'stockDisplay': 10, 'minStock': 5, 'maxStock': 20, 'emoji': '', 'discountPercent': 0.0, 'sku': 'SMK-005'},
      // Kebutuhan Harian
      {'id': 'K-001', 'name': 'Pepsodent White 190g', 'category': 'Kebutuhan Harian', 'price': 14500.0, 'costPrice': 12000.0, 'stockGudang': 80, 'stockDisplay': 20, 'minStock': 10, 'maxStock': 60, 'emoji': '', 'discountPercent': 0.0, 'sku': 'KBT-001'},
      {'id': 'K-002', 'name': 'Sabun Mandi Lifebuoy 110g', 'category': 'Kebutuhan Harian', 'price': 4500.0, 'costPrice': 3500.0, 'stockGudang': 150, 'stockDisplay': 30, 'minStock': 15, 'maxStock': 100, 'emoji': '', 'discountPercent': 0.0, 'sku': 'KBT-002'},
      {'id': 'K-003', 'name': 'Shampoo Clear 160ml', 'category': 'Kebutuhan Harian', 'price': 25000.0, 'costPrice': 21000.0, 'stockGudang': 60, 'stockDisplay': 15, 'minStock': 8, 'maxStock': 40, 'emoji': '', 'discountPercent': 0.0, 'sku': 'KBT-003'},
      {'id': 'K-004', 'name': 'Rinso Anti Noda 800g', 'category': 'Kebutuhan Harian', 'price': 23500.0, 'costPrice': 20000.0, 'stockGudang': 50, 'stockDisplay': 10, 'minStock': 10, 'maxStock': 40, 'emoji': '', 'discountPercent': 5.0, 'sku': 'KBT-004'},
      {'id': 'K-005', 'name': 'MamyPoko Pants L 30', 'category': 'Kebutuhan Bayi', 'price': 65000.0, 'costPrice': 58000.0, 'stockGudang': 40, 'stockDisplay': 5, 'minStock': 5, 'maxStock': 20, 'emoji': '', 'discountPercent': 0.0, 'sku': 'KBT-005'},
      // Obat
      {'id': 'O-001', 'name': 'Bodrex Flu & Batuk', 'category': 'Obat', 'price': 5000.0, 'costPrice': 4000.0, 'stockGudang': 100, 'stockDisplay': 20, 'minStock': 10, 'maxStock': 50, 'emoji': '', 'discountPercent': 0.0, 'sku': 'OBT-001'},
      {'id': 'O-002', 'name': 'Promag Strip', 'category': 'Obat', 'price': 8000.0, 'costPrice': 6500.0, 'stockGudang': 100, 'stockDisplay': 20, 'minStock': 10, 'maxStock': 50, 'emoji': '', 'discountPercent': 0.0, 'sku': 'OBT-002'},
      {'id': 'O-003', 'name': 'Tolak Angin Cair', 'category': 'Obat', 'price': 3500.0, 'costPrice': 2800.0, 'stockGudang': 200, 'stockDisplay': 40, 'minStock': 20, 'maxStock': 100, 'emoji': '', 'discountPercent': 0.0, 'sku': 'OBT-003'},
    ];

    for (var prod in dummyProducts) {
      await db.insert('products', prod);
    }

    // Generate Dummy Transactions
    final random = math.Random();
    final now = DateTime.now();
    final paymentMethods = ['Tunai', 'Tunai', 'Tunai', 'QRIS', 'QRIS', 'Kartu Debit', 'Transfer Bank'];

    for (int i = 1; i <= 65; i++) {
      final daysAgo = random.nextInt(8); // 0 to 7 days ago
      final hour = 8 + random.nextInt(14); // 8 AM to 9 PM
      final min = random.nextInt(60);
      final sec = random.nextInt(60);
      
      final dt = now.subtract(Duration(days: daysAgo));
      final dateStr = DateTime(dt.year, dt.month, dt.day, hour, min, sec).toIso8601String();
      
      final numItems = 1 + random.nextInt(4); // 1 to 4 unique items
      final selectedProducts = <Map<String, dynamic>>[];
      
      // Pick random products
      for (int j = 0; j < numItems; j++) {
        final prod = dummyProducts[random.nextInt(dummyProducts.length)];
        if (!selectedProducts.any((p) => p['id'] == prod['id'])) {
          selectedProducts.add(prod);
        }
      }

      double subtotal = 0;
      double totalDiscount = 0;
      
      final txId = 'TX-${DateTime.now().millisecondsSinceEpoch}-$i';
      
      final List<Map<String, dynamic>> itemsToInsert = [];

      for (var prod in selectedProducts) {
        final qty = 1 + random.nextInt(3);
        final price = prod['price'] as double;
        final discPct = prod['discountPercent'] as double;
        final discNominal = (price * discPct / 100) * qty;
        final itemSubtotal = (price * qty) - discNominal;
        
        subtotal += (price * qty);
        totalDiscount += discNominal;
        
        itemsToInsert.add({
          'id': 'ITEM-${random.nextInt(999999)}-$i',
          'transactionId': txId,
          'productId': prod['id'],
          'qty': qty,
          'price': price,
          'discount': discNominal,
        });
      }

      final total = subtotal - totalDiscount;
      final method = paymentMethods[random.nextInt(paymentMethods.length)];

      await db.insert('transactions', {
        'id': txId,
        'date': dateStr,
        'total': total,
        'discount': totalDiscount,
        'userId': '1',
        'paymentMethod': method,
        'customerId': '',
      });

      for (var item in itemsToInsert) {
        await db.insert('transaction_items', item);
      }
    }
  }

  static Future<void> _insertDefaultSettings(Database db) async {
    final defaults = {
      'store_name': 'Toko Faisal',
      'store_address': 'Jl. Contoh Alamat No. 123, Kota',
      'store_phone': '+62 812 3456 7890',
      'store_email': 'tokofaisal@email.com',
      'tax_enabled': 'false',
      'tax_percent': '11',
      'print_receipt': 'true',
      'sound_enabled': 'false',
      'receipt_footer': 'Terima kasih telah berbelanja!\nBarang yang sudah dibeli tidak dapat ditukar.',
      'points_per_rupiah': '1000',
      'points_value': '1',
    };

    for (var entry in defaults.entries) {
      try {
        await db.insert('settings', {'key': entry.key, 'value': entry.value});
      } catch (_) {}
    }
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
