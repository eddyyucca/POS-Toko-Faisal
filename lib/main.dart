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

import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  // Initialize window manager for fullscreen
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

  // Make sure database is initialized on startup
  await DatabaseHelper.instance.database;

  HardwareKeyboard.instance.addHandler((KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
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
    _NavPage(title: 'Dashboard', icon: Icons.dashboard_rounded),
    _NavPage(title: 'Kasir', icon: Icons.point_of_sale_rounded),
    _NavPage(title: 'Produk', icon: Icons.inventory_2_rounded),
    _NavPage(title: 'Opname', icon: Icons.checklist_rounded),
    _NavPage(title: 'Laporan', icon: Icons.bar_chart_rounded),
    _NavPage(title: 'Riwayat', icon: Icons.receipt_long_rounded),
    _NavPage(title: 'Pengaturan', icon: Icons.settings_rounded),
    _NavPage(title: 'Pengguna', icon: Icons.manage_accounts_rounded),
    _NavPage(title: 'Supplier', icon: Icons.local_shipping_rounded),
  ];

  Widget get _currentScreen {
    switch (_selectedIndex) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const PosScreen();
      case 2:
        return const ProductsScreen();
      case 3:
        return const OpnameScreen();
      case 4:
        return const ReportsScreen();
      case 5:
        return const HistoryScreen();
      case 6:
        return const SettingsScreen();
      case 7:
        return const UsersScreen();
      case 8:
        return const SuppliersScreen();
      default:
        return const DashboardScreen();
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

  Widget _buildTopBar() {
    final provider = context.watch<AppProvider>();
    final page = _pages[_selectedIndex];
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final dateStr = _formatDate(now);

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
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
          const Spacer(),
          _buildPingBadge(provider.pingMs),
          const SizedBox(width: 12),
          _buildStatusBadge(Icons.print_rounded, 'Printer OK', AppColors.primary),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  '$timeStr  •  $dateStr',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.danger),
            tooltip: 'Tutup Aplikasi',
            onPressed: () => windowManager.close(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(IconData icon, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 6, height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildPingBadge(int? pingMs) {
    Color color;
    String label;
    IconData icon;

    if (pingMs == null) {
      color = Colors.grey;
      label = 'Offline';
      icon = Icons.signal_wifi_connected_no_internet_4_rounded;
    } else if (pingMs < 200) {
      color = AppColors.success;
      label = '${pingMs}ms';
      icon = Icons.wifi_rounded;
    } else if (pingMs < 500) {
      color = AppColors.warning;
      label = '${pingMs}ms';
      icon = Icons.network_check_rounded;
    } else {
      color = AppColors.danger;
      label = '${pingMs}ms';
      icon = Icons.network_cell_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

class _NavPage {
  final String title;
  final IconData icon;
  const _NavPage({required this.title, required this.icon});
}
