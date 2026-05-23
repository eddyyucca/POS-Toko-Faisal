import 'dart:async';
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

  /// Delete transactional data that was successfully synced
  Future<void> _clearSyncedData(Map<String, dynamic> syncedIds) async {
    final db = await _db.database;

    // Transactional tables: DELETE synced records
    final transactionalTables = [
      'transactions', 'transaction_items', 'stock_opname',
      'purchases', 'purchase_items', 'void_transactions',
    ];

    for (final table in transactionalTables) {
      if (syncedIds.containsKey(table)) {
        final ids = List<String>.from(syncedIds[table]);
        if (ids.isNotEmpty) {
          final placeholders = ids.map((_) => '?').join(',');
          await db.rawDelete(
            'DELETE FROM $table WHERE id IN ($placeholders)',
            ids,
          );
        }
      }
    }

    // Master tables: Mark as synced (don't delete)
    final masterTables = ['products', 'customers', 'suppliers'];
    for (final table in masterTables) {
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
      for (final product in List<Map<String, dynamic>>.from(data['products'])) {
        // Remove server-specific fields
        product.remove('deleted_at');
        product.remove('created_at');
        product.remove('updated_at');
        product['sync_status'] = 'synced';
        
        await db.insert('products', product, conflictAlgorithm: ConflictAlgorithm.replace);
        count++;
      }
    }

    // Update customers from server
    if (data['customers'] != null) {
      for (final customer in List<Map<String, dynamic>>.from(data['customers'])) {
        customer.remove('created_at');
        customer.remove('updated_at');
        customer['sync_status'] = 'synced';
        
        await db.insert('customers', customer, conflictAlgorithm: ConflictAlgorithm.replace);
        count++;
      }
    }

    // Update suppliers from server
    if (data['suppliers'] != null) {
      for (final supplier in List<Map<String, dynamic>>.from(data['suppliers'])) {
        supplier.remove('created_at');
        supplier.remove('updated_at');
        supplier['sync_status'] = 'synced';
        
        await db.insert('suppliers', supplier, conflictAlgorithm: ConflictAlgorithm.replace);
        count++;
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
