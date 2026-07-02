import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common/sqlite_api.dart';
import '../database/database_helper.dart';
import 'api_client.dart';

/// Service that handles data synchronization between local SQLite and remote MySQL.
/// 
/// Sync flow:
/// 1. Collect all pending data from SQLite (sync_status = 'pending')
/// 2. Upload to Laravel API
/// 3. On success, delete synced transactional data from SQLite
/// 4. Download latest master data from server
/// 5. Update local master data
class SyncService {
  final ApiClient _apiClient;
  final DatabaseHelper _db = DatabaseHelper.instance;

  bool _isSyncing = false;
  String? _lastError;
  DateTime? _lastSyncTime;
  
  // Callbacks for progress updates
  void Function(String status)? onStatusChanged;
  void Function(double progress)? onProgressChanged;

  SyncService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  bool get isSyncing => _isSyncing;
  String? get lastError => _lastError;
  DateTime? get lastSyncTime => _lastSyncTime;
  ApiClient get apiClient => _apiClient;

  /// Set the server URL
  void setServerUrl(String url) {
    _apiClient.setBaseUrl(url);
  }

  /// Check if the server is reachable
  Future<bool> checkConnection() async {
    return await _apiClient.checkConnection();
  }

  /// Get count of pending data that needs to be synced
  Future<Map<String, int>> getPendingCounts() async {
    final db = await _db.database;
    final counts = <String, int>{};
    
    final tables = [
      'transactions', 'transaction_items', 'stock_opname',
      'purchases', 'purchase_items', 'void_transactions',
      'products', 'customers', 'suppliers',
    ];
    
    for (final table in tables) {
      try {
        final result = await db.rawQuery(
          "SELECT COUNT(*) as count FROM $table WHERE sync_status = 'pending'"
        );
        counts[table] = result.first['count'] as int? ?? 0;
      } catch (_) {
        counts[table] = 0;
      }
    }
    
    return counts;
  }

  /// Get total count of pending records
  Future<int> getTotalPendingCount() async {
    final counts = await getPendingCounts();
    int total = 0;
    for (var count in counts.values) {
      total += count;
    }
    return total;
  }

  /// Perform full sync: upload pending data, then download master data
  Future<SyncResult> syncAll() async {
    if (_isSyncing) {
      return SyncResult(
        success: false,
        message: 'Sinkronisasi sedang berjalan',
      );
    }

    _isSyncing = true;
    _lastError = null;
    onStatusChanged?.call('Memulai sinkronisasi...');
    onProgressChanged?.call(0.0);

    try {
      // Step 1: Check connection
      onStatusChanged?.call('Memeriksa koneksi server...');
      onProgressChanged?.call(0.1);
      
      final isConnected = await checkConnection();
      if (!isConnected) {
        throw Exception('Tidak dapat terhubung ke server');
      }

      // Step 2: Collect pending data
      onStatusChanged?.call('Mengumpulkan data pending...');
      onProgressChanged?.call(0.2);
      
      final pendingData = await _collectPendingData();
      final totalPending = pendingData.values
          .fold<int>(0, (sum, list) => sum + (list as List).length);

      int uploadedCount = 0;

      // Step 3: Upload if there's pending data
      if (totalPending > 0) {
        onStatusChanged?.call('Mengirim $totalPending data ke server...');
        onProgressChanged?.call(0.4);

        final uploadResult = await _apiClient.post('/sync/upload', body: pendingData);

        if (uploadResult['success'] == true) {
          // Step 4: Clear synced transactional data
          onStatusChanged?.call('Membersihkan data lokal...');
          onProgressChanged?.call(0.6);
          
          await _clearSyncedData(uploadResult['synced_ids'] ?? {});
          uploadedCount = totalPending;
        } else {
          throw Exception(uploadResult['message'] ?? 'Upload gagal');
        }
      }

      // Step 5: Download master data
      onStatusChanged?.call('Mengunduh data master terbaru...');
      onProgressChanged?.call(0.8);
      
      final downloadParams = <String, String>{};
      if (_lastSyncTime != null) {
        downloadParams['last_sync'] = _lastSyncTime!.toIso8601String();
      }
      
      final downloadResult = await _apiClient.get('/sync/download', queryParams: downloadParams.isNotEmpty ? downloadParams : null);
      
      int downloadedCount = 0;
      if (downloadResult['success'] == true && downloadResult['data'] != null) {
        downloadedCount = await _applyDownloadedData(downloadResult['data']);
      }

      // Done!
      onStatusChanged?.call('Sinkronisasi selesai!');
      onProgressChanged?.call(1.0);
      
      _lastSyncTime = DateTime.now();
      _isSyncing = false;

      // Save last sync time to settings
      final db = await _db.database;
      await db.insert('settings', {
        'key': 'last_sync_time',
        'value': _lastSyncTime!.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      return SyncResult(
        success: true,
        message: 'Sinkronisasi berhasil',
        uploadedCount: uploadedCount,
        downloadedCount: downloadedCount,
      );

    } catch (e) {
      _lastError = e.toString();
      _isSyncing = false;
      onStatusChanged?.call('Sinkronisasi gagal');
      onProgressChanged?.call(0.0);

      return SyncResult(
        success: false,
        message: 'Sinkronisasi gagal: ${e.toString()}',
      );
    }
  }

  /// Collect all data with sync_status = 'pending' from SQLite
  Future<Map<String, dynamic>> _collectPendingData() async {
    final db = await _db.database;
    final data = <String, dynamic>{};

    // Transactional data (will be deleted after sync)
    final transactionalTables = [
      'transactions', 'transaction_items', 'stock_opname',
      'purchases', 'purchase_items', 'void_transactions',
    ];

    for (final table in transactionalTables) {
      try {
        final rows = await db.query(table, where: "sync_status = 'pending'");
        if (rows.isNotEmpty) {
          data[table] = rows;
        }
      } catch (_) {
        // Table might not have sync_status yet
      }
    }

    // Master data (will be upserted, not deleted)
    final masterTables = ['products', 'customers', 'suppliers'];
    for (final table in masterTables) {
      try {
        final rows = await db.query(table, where: "sync_status = 'pending'");
        if (rows.isNotEmpty) {
          data[table] = rows;
        }
      } catch (_) {}
    }

    return data;
  }

  /// Mark synced data as 'synced' (keep locally for history, don't delete)
  Future<void> _clearSyncedData(Map<String, dynamic> syncedIds) async {
    final db = await _db.database;

    // Semua tabel: tandai 'synced', JANGAN dihapus agar history tetap bisa dilihat di app
    final allTables = [
      'transactions', 'transaction_items', 'stock_opname',
      'purchases', 'purchase_items', 'void_transactions',
      'products', 'customers', 'suppliers',
    ];

    for (final table in allTables) {
      if (syncedIds.containsKey(table)) {
        final ids = List<String>.from(syncedIds[table]);
        if (ids.isNotEmpty) {
          final placeholders = ids.map((_) => '?').join(',');
          await db.rawUpdate(
            "UPDATE $table SET sync_status = 'synced' WHERE id IN ($placeholders)",
            ids,
          );
        }
      }
    }
  }

  /// Apply downloaded master data to local SQLite
  Future<int> _applyDownloadedData(Map<String, dynamic> data) async {
    final db = await _db.database;
    int count = 0;

    // Update products from server
    if (data['products'] != null) {
      for (final raw in List<Map<String, dynamic>>.from(data['products'])) {
        try {
          final product = _filterFields(raw, {
            'id', 'name', 'category', 'price', 'costPrice',
            'stockGudang', 'stockDisplay', 'minStock', 'maxStock',
            'emoji', 'discountPercent', 'sku', 'unit',
            'unit2', 'unit2Conversion', 'unit2Price', 'sync_status',
          });
          // Pastikan field wajib tidak null/kosong
          if (product['id'] == null || product['name'] == null) continue;
          product['sync_status'] = 'synced';
          // Default value untuk field NOT NULL
          product['category']       ??= '';
          product['price']          ??= 0.0;
          product['costPrice']      ??= 0.0;
          product['stockGudang']    ??= 0;
          product['stockDisplay']   ??= 0;
          product['minStock']       ??= 0;
          product['maxStock']       ??= 0;
          product['emoji']          ??= '📦';
          product['discountPercent'] ??= 0.0;
          product['unit']           ??= 'Pcs';
          await db.insert('products', product,
              conflictAlgorithm: ConflictAlgorithm.replace);
          count++;
        } catch (e) {
          debugPrint('[Sync] Error insert product: $e | data: $raw');
        }
      }
    }

    // Update customers from server
    if (data['customers'] != null) {
      for (final raw in List<Map<String, dynamic>>.from(data['customers'])) {
        try {
          final customer = _filterFields(raw, {
            'id', 'name', 'phone', 'email', 'points', 'totalSpend',
            'createdAt', 'sync_status',
          });
          if (customer['id'] == null) continue;
          customer['sync_status'] = 'synced';
          customer['name']       ??= '';
          customer['phone']      ??= '';
          customer['createdAt']  ??= DateTime.now().toIso8601String();
          await db.insert('customers', customer,
              conflictAlgorithm: ConflictAlgorithm.replace);
          count++;
        } catch (e) {
          debugPrint('[Sync] Error insert customer: $e');
        }
      }
    }

    // Update suppliers from server
    if (data['suppliers'] != null) {
      for (final raw in List<Map<String, dynamic>>.from(data['suppliers'])) {
        try {
          final supplier = _filterFields(raw, {
            'id', 'name', 'phone', 'address', 'sync_status',
          });
          if (supplier['id'] == null) continue;
          supplier['sync_status'] = 'synced';
          supplier['name']    ??= '';
          supplier['phone']   ??= '';
          supplier['address'] ??= '';
          await db.insert('suppliers', supplier,
              conflictAlgorithm: ConflictAlgorithm.replace);
          count++;
        } catch (e) {
          debugPrint('[Sync] Error insert supplier: $e');
        }
      }
    }

    // Simpan transaksi dari backend (multi-kasir)
    // ConflictAlgorithm.ignore — jangan timpa transaksi lokal yg masih pending
    if (data['transactions'] != null) {
      for (final raw in List<Map<String, dynamic>>.from(data['transactions'])) {
        try {
          final txn   = Map<String, dynamic>.from(raw);
          final items = (txn.remove('items') as List<dynamic>? ?? [])
              .cast<Map<String, dynamic>>();

          final txnRow = _filterFields(txn, {
            'id', 'date', 'total', 'discount', 'amountPaid',
            'userId', 'paymentMethod', 'customerId', 'sync_status',
          });
          if (txnRow['id'] == null) continue;
          txnRow['sync_status'] = 'synced';
          txnRow['date']        ??= DateTime.now().toIso8601String();
          txnRow['total']       ??= 0.0;
          txnRow['discount']    ??= 0.0;
          txnRow['userId']      ??= '1';

          await db.insert('transactions', txnRow,
              conflictAlgorithm: ConflictAlgorithm.ignore);

          for (final item in items) {
            try {
              final itemRow = _filterFields(item, {
                'id', 'transactionId', 'productId', 'qty', 'price',
                'discount', 'unit', 'conversionQty', 'sync_status',
              });
              if (itemRow['id'] == null) continue;
              itemRow['sync_status'] = 'synced';
              itemRow['qty']         ??= 0;
              itemRow['price']       ??= 0.0;
              itemRow['discount']    ??= 0.0;
              await db.insert('transaction_items', itemRow,
                  conflictAlgorithm: ConflictAlgorithm.ignore);
            } catch (e) {
              debugPrint('[Sync] Error insert transaction_item: $e');
            }
          }
          count++;
        } catch (e) {
          debugPrint('[Sync] Error insert transaction: $e');
        }
      }
    }

    return count;
  }

  /// Load last sync time from settings
  Future<void> loadLastSyncTime() async {
    final db = await _db.database;
    try {
      final result = await db.query(
        'settings',
        where: "key = 'last_sync_time'",
      );
      if (result.isNotEmpty) {
        _lastSyncTime = DateTime.tryParse(result.first['value'] as String? ?? '');
      }
    } catch (_) {}
  }

  /// Filter map: hanya kembalikan key yang ada dalam [allowedKeys]
  Map<String, dynamic> _filterFields(
      Map<String, dynamic> raw, Set<String> allowedKeys) {
    return {
      for (final k in allowedKeys)
        if (raw.containsKey(k)) k: raw[k],
    };
  }
}

/// Result of a sync operation
class SyncResult {
  final bool success;
  final String message;
  final int uploadedCount;
  final int downloadedCount;

  SyncResult({
    required this.success,
    required this.message,
    this.uploadedCount = 0,
    this.downloadedCount = 0,
  });

  int get totalCount => uploadedCount + downloadedCount;
}
