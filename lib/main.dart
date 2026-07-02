import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'theme/app_theme.dart';
import 'widgets/sidebar_nav.dart';
import 'screens/dashboard_screen.dart';
import 'screens/pos_screen.dart';
import 'screens/products_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/login_screen.dart';
import 'screens/opname_screen.dart';
import 'screens/users_screen.dart';
import 'screens/suppliers_screen.dart';
import 'providers/app_provider.dart';
import 'database/database_helper.dart';
import 'config/app_config.dart';

import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  await windowManager.ensureInitialized();
  WindowOptions windowOptions = const WindowOptions(
    title: 'Toko Faisal POS',
    center: true,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setFullScreen(true);
    await windowManager.show();
    await windowManager.focus();
  });

  await DatabaseHelper.instance.database;

  HardwareKeyboard.instance.addHandler((KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      navigatorKey.currentState?.maybePop();
      return true;
    }
    return false;
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()..loadProducts()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Toko Faisal POS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const LoginScreen(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  static const List<_NavPage> _pages = [
    _NavPage(title: 'Dashboard',  icon: Icons.dashboard_rounded),
    _NavPage(title: 'Kasir',      icon: Icons.point_of_sale_rounded),
    _NavPage(title: 'Produk',     icon: Icons.inventory_2_rounded),
    _NavPage(title: 'Opname',     icon: Icons.checklist_rounded),
    _NavPage(title: 'Laporan',    icon: Icons.bar_chart_rounded),
    _NavPage(title: 'Riwayat',    icon: Icons.receipt_long_rounded),
    _NavPage(title: 'Pengaturan', icon: Icons.settings_rounded),
    _NavPage(title: 'Pengguna',   icon: Icons.manage_accounts_rounded),
    _NavPage(title: 'Supplier',   icon: Icons.local_shipping_rounded),
  ];

  Widget get _currentScreen {
    switch (_selectedIndex) {
      case 0:  return const DashboardScreen();
      case 1:  return const PosScreen();
      case 2:  return const ProductsScreen();
      case 3:  return const OpnameScreen();
      case 4:  return const ReportsScreen();
      case 5:  return const HistoryScreen();
      case 6:  return const SettingsScreen();
      case 7:  return const UsersScreen();
      case 8:  return const SuppliersScreen();
      default: return const DashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SidebarNav(
            selectedIndex: _selectedIndex,
            onItemSelected: (i) => setState(() => _selectedIndex = i),
          ),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(child: _currentScreen),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Top Bar ────────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    final provider = context.watch<AppProvider>();
    final page     = _pages[_selectedIndex];
    final now      = DateTime.now();
    final timeStr  = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final dateStr  = _formatDate(now);

    final screenWidth = MediaQuery.of(context).size.width;
    final hideDateTime = screenWidth < 900;
    final hidePingHost = screenWidth < 750;
    final hideDevLabel = screenWidth < 680;
    final hideTitle    = screenWidth < 550;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          // ── Page icon + title ──────────────────────────────────────────────
          if (!hideTitle) ...[
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.primaryLightBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(page.icon, size: 16, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Text(
              page.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],

          const Spacer(),

          // ── ENV label (hanya muncul saat DEV) ─────────────────────────────
          if (AppConfig.isDev && !hideDevLabel) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
              ),
              child: const Text(
                'DEV · localhost:8000',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // ── Badge kiri: Sync status (GET/POST aktif) ───────────────────────
          _SyncBadge(isRequesting: provider.isRequesting),
          const SizedBox(width: 8),

          // ── Badge kanan: Ping ke server ───────────────────────────────────
          _PingBadge(pingMs: provider.pingMs, hideHost: hidePingHost),
          const SizedBox(width: 16),

          // ── Jam & tanggal ──────────────────────────────────────────────────
          if (!hideDateTime) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time_rounded,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    '$timeStr  •  $dateStr',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
          ],

          // ── Jam & tanggal / Tutup ──────────────────────────────────────────
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.danger),
            tooltip: 'Tutup Aplikasi',
            onPressed: () => windowManager.close(),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const m = [
      'Jan','Feb','Mar','Apr','Mei','Jun',
      'Jul','Ags','Sep','Okt','Nov','Des',
    ];
    return '${dt.day} ${m[dt.month - 1]} ${dt.year}';
  }
}

// ── Badge kiri: Sync status ────────────────────────────────────────────────────
class _SyncBadge extends StatelessWidget {
  final bool isRequesting;
  const _SyncBadge({required this.isRequesting});

  @override
  Widget build(BuildContext context) {
    final active = isRequesting;
    final color       = active ? AppColors.primary        : AppColors.textSecondary;
    final bgColor     = active ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent;
    final borderColor = active ? AppColors.primary.withValues(alpha: 0.35) : AppColors.border;
    final label       = active ? 'Syncing...' : 'Idle';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Spinner saat aktif, ikon sync saat idle
          SizedBox(
            width: 11,
            height: 11,
            child: active
                ? CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: AppColors.primary,
                  )
                : Icon(Icons.sync_rounded, size: 11, color: color),
          ),
          const SizedBox(width: 5),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: Text(
              label,
              key: ValueKey(label),
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Badge kanan: Ping domain ───────────────────────────────────────────────────
class _PingBadge extends StatelessWidget {
  final int? pingMs;
  final bool hideHost;
  const _PingBadge({required this.pingMs, this.hideHost = false});

  @override
  Widget build(BuildContext context) {
    final Color    color;
    final IconData icon;
    final String   latency;

    if (pingMs == null) {
      color   = Colors.grey;
      icon    = Icons.signal_wifi_connected_no_internet_4_rounded;
      latency = 'Offline';
    } else if (pingMs! < 200) {
      color   = AppColors.success;
      icon    = Icons.wifi_rounded;
      latency = '${pingMs}ms';
    } else if (pingMs! < 500) {
      color   = AppColors.warning;
      icon    = Icons.network_check_rounded;
      latency = '${pingMs}ms';
    } else {
      color   = AppColors.danger;
      icon    = Icons.network_cell_rounded;
      latency = '${pingMs}ms';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          if (!hideHost) ...[
            const SizedBox(width: 5),
            Text(
              'tokofaisal.fluxa.co.id',
              style: TextStyle(
                color: color.withValues(alpha: 0.75),
                fontSize: 10,
                fontWeight: FontWeight.w400,
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              width: 1,
              height: 10,
              color: color.withValues(alpha: 0.35),
            ),
          ] else ...[
            const SizedBox(width: 4),
          ],
          // Latensi / Offline
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: Text(
              latency,
              key: ValueKey(latency),
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavPage {
  final String title;
  final IconData icon;
  const _NavPage({required this.title, required this.icon});
}
