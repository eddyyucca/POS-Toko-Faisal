import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

/// HTTP client wrapper for communicating with the Laravel backend API.
class ApiClient {
  String _baseUrl;
  final Duration _timeout;
  String? _token;

  ApiClient({
    this._baseUrl = 'https://tokofaisal.fluxa.co.id/api',
    this._timeout = const Duration(seconds: 30),
  });

  /// Update the base URL (e.g. from settings)
  void setBaseUrl(String url) {
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  String get baseUrl => _baseUrl;

  /// Set Bearer token for authenticated requests
  void setToken(String token) {
    _token = token;
  }

  /// Clear saved token (on logout)
  void clearToken() {
    _token = null;
  }

  bool get hasToken => _token != null && _token!.isNotEmpty;

  /// GET request
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _headers).timeout(_timeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException('Koneksi timeout. Periksa koneksi jaringan Anda.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal terhubung ke server: ${e.toString()}');
    }
  }

  /// POST request
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final response = await http
          .post(uri, headers: _headers, body: jsonEncode(body ?? {}))
          .timeout(_timeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException('Koneksi timeout. Periksa koneksi jaringan Anda.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal terhubung ke server: ${e.toString()}');
    }
  }

  /// POST without auth (for login endpoint)
  Future<Map<String, dynamic>> postPublic(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      final response = await http
          .post(uri, headers: headers, body: jsonEncode(body ?? {}))
          .timeout(_timeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException('Koneksi timeout. Periksa koneksi jaringan Anda.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal terhubung ke server: ${e.toString()}');
    }
  }

  /// Check server connectivity
  Future<bool> checkConnection() async {
    try {
      final response = await get('/sync/status');
      return response['status'] == 'online';
    } catch (_) {
      return false;
    }
  }

  /// Check ping (latency) to server in milliseconds
  Future<int?> checkPing() async {
    final stopwatch = Stopwatch()..start();
    try {
      final response = await get('/sync/status');
      stopwatch.stop();
      if (response['status'] == 'online') {
        return stopwatch.elapsedMilliseconds;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else if (response.statusCode == 401) {
      throw ApiException('Sesi habis. Silakan login ulang.');
    } else if (response.statusCode == 422) {
      throw ApiException('Data tidak valid: ${body['message'] ?? 'Validation error'}');
    } else if (response.statusCode == 500) {
      throw ApiException('Server error: ${body['message'] ?? 'Internal server error'}');
    } else {
      throw ApiException('Error ${response.statusCode}: ${body['message'] ?? 'Unknown error'}');
    }
  }
}

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
