/// Konfigurasi environment aplikasi.
///
/// Cara pakai:
///   Development : flutter run --dart-define=FLAVOR=dev
///   Production  : flutter run   (atau tanpa flag → default prod)
///
/// Untuk build release produksi:
///   flutter build windows --dart-define=FLAVOR=prod

// ignore_for_file: constant_identifier_names
const _FLAVOR = String.fromEnvironment('FLAVOR', defaultValue: 'prod');

class AppConfig {
  AppConfig._();

  // ── Environment ────────────────────────────────────────────────────────────
  static bool get isDev  => _FLAVOR == 'dev';
  static bool get isProd => !isDev;

  static String get flavorLabel => isDev ? 'DEV' : 'PROD';

  // ── API Base URL ───────────────────────────────────────────────────────────
  static String get apiBaseUrl =>
      isDev ? 'http://localhost:8000/api' : 'https://tokofaisal.fluxa.co.id/api';

  // ── Ping URL (untuk cek koneksi, tidak pakai auth header) ─────────────────
  static String get pingUrl =>
      isDev ? 'http://localhost:8000/api/sync/status'
            : 'https://tokofaisal.fluxa.co.id/api/sync/status';

  // ── Label domain yang tampil di badge top bar ──────────────────────────────
  static String get pingDisplayHost =>
      isDev ? 'localhost:8000' : 'tokofaisal.fluxa.co.id';

  // ── Timeout ────────────────────────────────────────────────────────────────
  static Duration get requestTimeout =>
      isDev ? const Duration(seconds: 10) : const Duration(seconds: 15);

  static Duration get pingTimeout =>
      isDev ? const Duration(seconds: 4) : const Duration(seconds: 8);
}
