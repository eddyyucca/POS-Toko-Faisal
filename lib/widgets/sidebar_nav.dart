import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_provider.dart';
import '../screens/login_screen.dart';

class SidebarNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const SidebarNav({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final role = provider.currentUser?.role ?? 'Kasir';
    final isAdmin = role == 'Admin';
    final lowStockCount = provider.lowStockCount;

    final screenWidth = MediaQuery.of(context).size.width;
    final isCollapse = screenWidth < 950;

    return Container(
      width: isCollapse ? 72 : 220,
      color: AppColors.sidebar,
      child: Column(
        children: [
          _buildHeader(context, provider, isCollapse),
          const SizedBox(height: 8),
          // Dashboard
          _buildNavItem(0, Icons.dashboard_rounded, 'Dashboard', isCollapse),
          // Kasir
          _buildNavItem(1, Icons.point_of_sale_rounded, 'Kasir', isCollapse),
          // Produk dengan badge stok menipis
          _buildNavItemWithBadge(2, Icons.inventory_2_rounded, 'Produk', lowStockCount, isCollapse),

          // Opname
          _buildNavItem(3, Icons.checklist_rounded, 'Opname', isCollapse),
          // Laporan (admin only)
          if (isAdmin) _buildNavItem(4, Icons.bar_chart_rounded, 'Laporan', isCollapse),
          // Riwayat
          _buildNavItem(5, Icons.receipt_long_rounded, 'Riwayat', isCollapse),
          // Supplier (admin only)
          if (isAdmin) _buildNavItem(8, Icons.local_shipping_rounded, 'Supplier', isCollapse),
          const Spacer(),
          // Pengguna (admin only)
          if (isAdmin) _buildNavItem(7, Icons.manage_accounts_rounded, 'Pengguna', isCollapse),
          // Pengaturan (admin only)
          if (isAdmin) _buildNavItem(6, Icons.settings_rounded, 'Pengaturan', isCollapse),
          _buildUserFooter(context, isCollapse),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppProvider provider, bool isCollapse) {
    final pendingCount = provider.pendingSyncCount;
    final isSyncing    = provider.isSyncing;

    // Status: Menyinkron → Tertunda → Tersinkron
    final Color    badgeColor;
    final Color    badgeBorder;
    final IconData badgeIcon;
    final String   badgeLabel;
    final Color    badgeTextColor;

    if (isSyncing) {
      badgeColor     = AppColors.primary.withValues(alpha: 0.2);
      badgeBorder    = AppColors.primary.withValues(alpha: 0.5);
      badgeIcon      = Icons.sync_rounded;
      badgeLabel     = 'Menyinkron...';
      badgeTextColor = AppColors.primary;
    } else if (pendingCount > 0) {
      badgeColor     = AppColors.warning.withValues(alpha: 0.2);
      badgeBorder    = AppColors.warning.withValues(alpha: 0.5);
      badgeIcon      = Icons.cloud_upload_rounded;
      badgeLabel     = '$pendingCount Tertunda';
      badgeTextColor = AppColors.warning;
    } else {
      badgeColor     = AppColors.success.withValues(alpha: 0.2);
      badgeBorder    = AppColors.success.withValues(alpha: 0.5);
      badgeIcon      = Icons.cloud_done_rounded;
      badgeLabel     = 'Tersinkron';
      badgeTextColor = AppColors.success;
    }

    if (isCollapse) {
      return GestureDetector(
        onTap: isSyncing
            ? null
            : () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Memulai sinkronisasi data...'),
                    duration: Duration(seconds: 1),
                  ),
                );
                final result = await provider.performSync();
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(result.success
                        ? 'Sinkronisasi berhasil! Data diperbarui.'
                        : 'Gagal sinkron: ${result.message}'),
                    backgroundColor: result.success ? AppColors.success : AppColors.danger,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logo_circle.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: badgeTextColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.sidebar, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.5),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo_circle.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Toko Faisal',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Sembako & Kebutuhan Harian',
                  style: TextStyle(
                    color: AppColors.sidebarBadge,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                // Badge sync (Bisa diklik untuk trigger Sync manual)
                GestureDetector(
                  onTap: isSyncing
                      ? null
                      : () async {
                          final scaffoldMessenger = ScaffoldMessenger.of(context);
                          scaffoldMessenger.showSnackBar(
                            const SnackBar(
                              content: Text('Memulai sinkronisasi data...'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                          final result = await provider.performSync();
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text(result.success
                                  ? 'Sinkronisasi berhasil! Data diperbarui.'
                                  : 'Gagal sinkron: ${result.message}'),
                              backgroundColor: result.success ? AppColors.success : AppColors.danger,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: badgeBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(badgeIcon, color: badgeTextColor, size: 10),
                          const SizedBox(width: 4),
                          Text(
                            badgeLabel,
                            style: TextStyle(
                              color: badgeTextColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, bool isCollapse) {
    final bool isActive = selectedIndex == index;

    if (isCollapse) {
      return GestureDetector(
        onTap: () => onItemSelected(index),
        child: Container(
          width: 44,
          height: 44,
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary.withValues(alpha: 0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isActive
                ? Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1)
                : null,
          ),
          child: Center(
            child: Icon(
              icon,
              color: isActive ? AppColors.primaryLight : AppColors.sidebarInactive,
              size: 20,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => onItemSelected(index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isActive
              ? Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.primaryLight : AppColors.sidebarInactive,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : AppColors.sidebarInactive,
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
            if (isActive) ...[
              const Spacer(),
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNavItemWithBadge(int index, IconData icon, String label, int badgeCount, bool isCollapse) {
    final bool isActive = selectedIndex == index;

    if (isCollapse) {
      return GestureDetector(
        onTap: () => onItemSelected(index),
        child: Container(
          width: 44,
          height: 44,
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary.withValues(alpha: 0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isActive
                ? Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1)
                : null,
          ),
          child: Center(
            child: Badge(
              label: Text('$badgeCount'),
              isLabelVisible: badgeCount > 0,
              backgroundColor: AppColors.danger,
              textColor: Colors.white,
              child: Icon(
                icon,
                color: isActive ? AppColors.primaryLight : AppColors.sidebarInactive,
                size: 20,
              ),
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => onItemSelected(index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isActive
              ? Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.primaryLight : AppColors.sidebarInactive,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : AppColors.sidebarInactive,
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
            if (badgeCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else if (isActive)
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserFooter(BuildContext context, bool isCollapse) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final username = provider.currentUser?.username ?? 'Admin';
        final role = provider.currentUser?.role ?? 'Kasir';
        final initial = username.isNotEmpty ? username[0].toUpperCase() : 'A';

        if (isCollapse) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: GestureDetector(
              onTap: () async {
                final bool? logout = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Keluar Aplikasi'),
                    content: const Text('Apakah Anda yakin ingin logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Batal'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Keluar', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (logout == true) {
                  await provider.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  }
                }
              },
              child: Tooltip(
                message: 'Keluar ($username)',
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.sidebarActive,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.sidebarActive,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(username, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    Text(role, style: const TextStyle(color: AppColors.sidebarInactive, fontSize: 11)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () async {
                  await provider.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  }
                },
                child: const Icon(Icons.logout_rounded, color: AppColors.sidebarInactive, size: 17),
              ),
            ],
          ),
        );
      },
    );
  }
}
