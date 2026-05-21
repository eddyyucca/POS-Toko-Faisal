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
    final role = Provider.of<AppProvider>(context).currentUser?.role ?? 'Kasir';
    final isAdmin = role == 'Admin';

    return Container(
      width: 230,
      color: AppColors.sidebar,
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 8),
          _buildNavItem(0, Icons.point_of_sale_rounded, 'Kasir'),
          _buildNavItem(1, Icons.inventory_2_rounded, 'Produk'),
          if (isAdmin) _buildNavItem(7, Icons.local_shipping_rounded, 'Supplier'),
          _buildNavItem(2, Icons.checklist_rounded, 'Opname'),
          if (isAdmin) _buildNavItem(3, Icons.bar_chart_rounded, 'Laporan'),
          _buildNavItem(4, Icons.receipt_long_rounded, 'Riwayat'),
          const Spacer(),
          if (isAdmin) _buildNavItem(6, Icons.people_rounded, 'Pengguna'),
          if (isAdmin) _buildNavItem(5, Icons.settings_rounded, 'Pengaturan'),
          _buildUserFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08))),
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
                  color: AppColors.primary.withOpacity(0.5),
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Toko Faisal',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Sembako & Kebutuhan Harian',
                  style: TextStyle(
                    color: Color(0xFFFFB347),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
          color: isActive ? AppColors.primary.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isActive
              ? Border.all(color: AppColors.primary.withOpacity(0.5), width: 1)
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
            border: Border.all(color: Colors.white.withOpacity(0.06)),
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
