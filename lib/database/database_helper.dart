import 'dart:io';
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
        version: 3,
        onCreate: _createDB,
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 3) {
            await db.execute('DROP TABLE IF EXISTS users');
            await db.execute('DROP TABLE IF EXISTS products');
            await db.execute('DROP TABLE IF EXISTS transactions');
            await db.execute('DROP TABLE IF EXISTS transaction_items');
            await db.execute('DROP TABLE IF EXISTS stock_opname');
            await db.execute('DROP TABLE IF EXISTS suppliers');
            await db.execute('DROP TABLE IF EXISTS purchases');
            await db.execute('DROP TABLE IF EXISTS purchase_items');
            await _createDB(db, newVersion);
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
        role $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id $idType,
        name $textType,
        category $textType,
        price $realType,
        stockGudang $integerType,
        stockDisplay $integerType,
        minStock $integerType,
        maxStock $integerType,
        emoji $textType,
        discountPercent $realType
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id $idType,
        date $textType,
        total $realType,
        discount $realType,
        userId $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE transaction_items (
        id $idType,
        transactionId $textType,
        productId $textType,
        qty $integerType,
        price $realType,
        discount $realType
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
        userId $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE suppliers (
        id $idType,
        name $textType,
        phone $textType,
        address $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE purchases (
        id $idType,
        date $textType,
        supplierId $textType,
        total $realType,
        notes TEXT,
        userId $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE purchase_items (
        id $idType,
        purchaseId $textType,
        productId $textType,
        qty $integerType,
        costPrice $realType
      )
    ''');

    // Insert Default User (admin/admin)
    await db.insert('users', {
      'id': '1',
      'username': 'admin',
      'password': 'admin', // in real app, should be hashed
      'role': 'Admin',
    });

    // Insert Dummy Products for initial database setup
    final dummyProducts = [
      {'id': '1', 'name': 'Indomie Goreng', 'category': 'Makanan', 'price': 3000.0, 'stockGudang': 200, 'stockDisplay': 50, 'minStock': 20, 'maxStock': 100, 'emoji': '🍜', 'discountPercent': 0.0},
      {'id': '2', 'name': 'Beras Maknyus 5Kg', 'category': 'Sembako', 'price': 70000.0, 'stockGudang': 50, 'stockDisplay': 10, 'minStock': 5, 'maxStock': 30, 'emoji': '🌾', 'discountPercent': 0.0},
      {'id': '3', 'name': 'Minyak Goreng Bimoli 2L', 'category': 'Sembako', 'price': 35000.0, 'stockGudang': 40, 'stockDisplay': 15, 'minStock': 5, 'maxStock': 25, 'emoji': '🛢️', 'discountPercent': 0.0},
      {'id': '4', 'name': 'Sabun Mandi Lifebuoy', 'category': 'Kebutuhan Harian', 'price': 4500.0, 'stockGudang': 100, 'stockDisplay': 30, 'minStock': 10, 'maxStock': 50, 'emoji': '🧼', 'discountPercent': 0.0},
      {'id': '5', 'name': 'Shampoo Clear 170ml', 'category': 'Kebutuhan Harian', 'price': 22000.0, 'stockGudang': 30, 'stockDisplay': 10, 'minStock': 5, 'maxStock': 20, 'emoji': '🧴', 'discountPercent': 5.0},
      {'id': '6', 'name': 'Gula Pasir Gulaku 1Kg', 'category': 'Sembako', 'price': 16500.0, 'stockGudang': 60, 'stockDisplay': 20, 'minStock': 10, 'maxStock': 40, 'emoji': '🍚', 'discountPercent': 0.0},
      {'id': '7', 'name': 'Kopi Kapal Api Sachet (Isi 10)', 'category': 'Minuman', 'price': 12000.0, 'stockGudang': 80, 'stockDisplay': 20, 'minStock': 10, 'maxStock': 40, 'emoji': '☕', 'discountPercent': 0.0},
      {'id': '8', 'name': 'Susu Bear Brand', 'category': 'Minuman', 'price': 10500.0, 'stockGudang': 50, 'stockDisplay': 20, 'minStock': 10, 'maxStock': 40, 'emoji': '🥛', 'discountPercent': 0.0},
      {'id': '9', 'name': 'Roti Tawar Sari Roti', 'category': 'Makanan', 'price': 16000.0, 'stockGudang': 0, 'stockDisplay': 15, 'minStock': 5, 'maxStock': 20, 'emoji': '🍞', 'discountPercent': 0.0},
    ];

    for (var prod in dummyProducts) {
      await db.insert('products', prod);
    }
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
