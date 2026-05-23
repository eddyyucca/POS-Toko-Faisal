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

    return Container(
      width: 230,
      color: AppColors.sidebar,
      child: Column(
        children: [
          _buildHeader(provider),
          const SizedBox(height: 8),
          // Dashboard
          _buildNavItem(0, Icons.dashboard_rounded, 'Dashboard'),
          // Kasir
          _buildNavItem(1, Icons.point_of_sale_rounded, 'Kasir'),
          // Produk dengan badge stok menipis
          _buildNavItemWithBadge(2, Icons.inventory_2_rounded, 'Produk', lowStockCount),

          // Opname
          _buildNavItem(3, Icons.checklist_rounded, 'Opname'),
          // Laporan (admin only)
          if (isAdmin) _buildNavItem(4, Icons.bar_chart_rounded, 'Laporan'),
          // Riwayat
          _buildNavItem(5, Icons.receipt_long_rounded, 'Riwayat'),
          // Supplier (admin only)
          if (isAdmin) _buildNavItem(8, Icons.local_shipping_rounded, 'Supplier'),
          const Spacer(),
          // Pengguna (admin only)
          if (isAdmin) _buildNavItem(7, Icons.manage_accounts_rounded, 'Pengguna'),
          // Pengaturan (admin only)
          if (isAdmin) _buildNavItem(6, Icons.settings_rounded, 'Pengaturan'),
          _buildUserFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(AppProvider provider) {
    final pendingCount = provider.pendingSyncCount;
    final isSyncing = provider.isSyncing;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: Row(
        children: [
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
                    color: Color(0xFFFFB347),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: pendingCount > 0 ? AppColors.warning.withValues(alpha: 0.2) : AppColors.success.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: pendingCount > 0 ? AppColors.warning.withValues(alpha: 0.5) : AppColors.success.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSyncing ? Icons.sync_rounded : (pendingCount > 0 ? Icons.cloud_upload_rounded : Icons.cloud_done_rounded),
                        color: pendingCount > 0 ? AppColors.warning : AppColors.success,
                        size: 10,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isSyncing ? 'Menyinkron...' : (pendingCount > 0 ? '$pendingCount Tertunda' : 'Tersinkron'),
                        style: TextStyle(
                          color: pendingCount > 0 ? AppColors.warning : AppColors.success,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isActive = selectedIndex == index;
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
              color: isActive ? AppColors.primaryLight : const Color(0xFF8FA3B4),
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFF8FA3B4),
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

  Widget _buildNavItemWithBadge(int index, IconData icon, String label, int badgeCount) {
    final bool isActive = selectedIndex == index;
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
              color: isActive ? AppColors.primaryLight : const Color(0xFF8FA3B4),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : const Color(0xFF8FA3B4),
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

  Widget _buildUserFooter(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final username = provider.currentUser?.username ?? 'Admin';
        final role = provider.currentUser?.role ?? 'Kasir';
        final initial = username.isNotEmpty ? username[0].toUpperCase() : 'A';

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
                    Text(role, style: const TextStyle(color: Color(0xFF8FA3B4), fontSize: 11)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  provider.logout();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: const Icon(Icons.logout_rounded, color: Color(0xFF8FA3B4), size: 17),
              ),
            ],
          ),
        );
      },
    );
  }
}
