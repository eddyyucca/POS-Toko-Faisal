import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// HTTP client wrapper for communicating with the Laravel backend API.
class ApiClient {
  String _baseUrl;
  final Duration _timeout;
  String? _token;

  // ── Request activity tracking ──────────────────────────────────────────────
  /// Dipanggil setiap kali jumlah request aktif berubah (untuk update UI)
  void Function(int activeCount)? onActiveRequestsChanged;

  int _activeRequests = 0;

  /// True jika sedang ada request HTTP GET/POST yang berjalan
  bool get isRequesting => _activeRequests > 0;

  void _inc() {
    _activeRequests++;
    onActiveRequestsChanged?.call(_activeRequests);
  }

  void _dec() {
    if (_activeRequests > 0) _activeRequests--;
    onActiveRequestsChanged?.call(_activeRequests);
  }

  ApiClient({
    String? baseUrl,
    Duration? timeout,
  })  : _baseUrl = baseUrl ?? AppConfig.apiBaseUrl,
        _timeout = timeout ?? AppConfig.requestTimeout;

  void setBaseUrl(String url) {
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  String get baseUrl => _baseUrl;

  void setToken(String token) => _token = token;
  void clearToken() => _token = null;
  bool get hasToken => _token != null && _token!.isNotEmpty;

  // ── GET ────────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    _inc();
    try {
      final uri = Uri.parse('$_baseUrl$endpoint')
          .replace(queryParameters: queryParams);
      final response =
          await http.get(uri, headers: _authHeaders).timeout(_timeout);
      return _handle(response);
    } on TimeoutException {
      throw ApiException('Koneksi timeout. Periksa jaringan Anda.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal terhubung ke server.');
    } finally {
      _dec();
    }
  }

  // ── POST (authenticated) ───────────────────────────────────────────────────
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    _inc();
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final response = await http
          .post(uri, headers: _authHeaders, body: jsonEncode(body ?? {}))
          .timeout(_timeout);
      return _handle(response);
    } on TimeoutException {
      throw ApiException('Koneksi timeout. Periksa jaringan Anda.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal terhubung ke server.');
    } finally {
      _dec();
    }
  }

  // ── POST public (login — tanpa auth token) ─────────────────────────────────
  Future<Map<String, dynamic>> postPublic(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    _inc();
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final response = await http
          .post(uri, headers: _publicHeaders, body: jsonEncode(body ?? {}))
          .timeout(_timeout);
      return _handle(response);
    } on TimeoutException {
      throw ApiException('Koneksi timeout. Periksa jaringan Anda.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal terhubung ke server.');
    } finally {
      _dec();
    }
  }

  // ── Ping — TIDAK menambah activeRequests ──────────────────────────────────
  /// Mengembalikan latensi dalam ms, atau null jika tidak bisa dijangkau.
  /// Pakai dart:io HttpClient agar reliable di Windows desktop (HTTPS).
  Future<int?> checkPing() async {
    final sw = Stopwatch()..start();
    HttpClient? client;
    try {
      client = HttpClient();
      client.badCertificateCallback = (_, __, ___) => true;
      client.connectionTimeout = AppConfig.pingTimeout;

      final uri = Uri.parse(AppConfig.pingUrl);
      final request = await client.getUrl(uri);
      request.headers.set('Accept', 'application/json');

      final response = await request.close()
          .timeout(AppConfig.pingTimeout);

      // Drain response body agar koneksi ditutup dengan benar
      await response.drain<void>();
      sw.stop();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return sw.elapsedMilliseconds;
      }
      debugPrint('[Ping] Status ${response.statusCode}');
      return null;
    } on TimeoutException {
      debugPrint('[Ping] Timeout (${AppConfig.pingTimeout.inSeconds}s) → ${AppConfig.pingUrl}');
      return null;
    } on SocketException catch (e) {
      debugPrint('[Ping] SocketException: $e');
      return null;
    } catch (e) {
      debugPrint('[Ping] Error: $e');
      return null;
    } finally {
      client?.close(force: true);
    }
  }

  // ── Helper: check koneksi (bool) ───────────────────────────────────────────
  Future<bool> checkConnection() async => (await checkPing()) != null;

  // ── Headers ────────────────────────────────────────────────────────────────
  Map<String, String> get _authHeaders {
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (hasToken) h['Authorization'] = 'Bearer $_token';
    return h;
  }

  Map<String, String> get _publicHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // ── Response handler ───────────────────────────────────────────────────────
  Map<String, dynamic> _handle(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final code = response.statusCode;
    if (code >= 200 && code < 300) return body;
    if (code == 401) throw ApiException('Sesi habis. Silakan login ulang.');
    if (code == 422) {
      throw ApiException(
          'Data tidak valid: ${body['message'] ?? 'Validation error'}');
    }
    if (code == 500) {
      throw ApiException(
          'Server error: ${body['message'] ?? 'Internal server error'}');
    }
    throw ApiException('Error $code: ${body['message'] ?? 'Unknown error'}');
  }
}

/// Custom exception untuk error API
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
