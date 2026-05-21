import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'widgets/sidebar_nav.dart';
import 'screens/pos_screen.dart';
import 'screens/products_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Toko Faisal POS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const MainShell(),
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
    _NavPage(title: 'Kasir', icon: Icons.point_of_sale_rounded),
    _NavPage(title: 'Produk', icon: Icons.inventory_2_rounded),
    _NavPage(title: 'Laporan', icon: Icons.bar_chart_rounded),
    _NavPage(title: 'Riwayat', icon: Icons.receipt_long_rounded),
    _NavPage(title: 'Pengaturan', icon: Icons.settings_rounded),
  ];

  Widget get _currentScreen {
    switch (_selectedIndex) {
      case 0: return const PosScreen();
      case 1: return const ProductsScreen();
      case 2: return const ReportsScreen();
      case 3: return const HistoryScreen();
      case 4: return const SettingsScreen();
      default: return const PosScreen();
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
              color: AppColors.orangeLight,
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
          _buildStatusBadge(Icons.wifi_rounded, 'Online', AppColors.accent),
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
