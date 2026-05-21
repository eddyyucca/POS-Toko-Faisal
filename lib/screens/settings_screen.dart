import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _printReceipt = true;
  bool _taxEnabled = true;
  bool _soundEnabled = false;
  bool _darkMode = false;
  int _selectedPrinter = 0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pengaturan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          const Text('Konfigurasi aplikasi POS Anda', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildSection('Informasi Toko', [
                      _buildTextField('Nama Toko', 'TokoKu', Icons.store_rounded),
                      _buildTextField('Alamat', 'Jl. Merdeka No. 10, Jakarta', Icons.location_on_rounded),
                      _buildTextField('No. Telepon', '+62 812 3456 7890', Icons.phone_rounded),
                      _buildTextField('Email', 'tokoku@email.com', Icons.email_rounded),
                    ]),
                    const SizedBox(height: 20),
                    _buildSection('Konfigurasi Pajak', [
                      _buildSwitch('Aktifkan PPN', 'Pajak 11% diterapkan pada setiap transaksi', _taxEnabled, (v) => setState(() => _taxEnabled = v)),
                      _buildTextField('Persentase Pajak', '11%', Icons.percent_rounded),
                    ]),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _buildSection('Preferensi', [
                      _buildSwitch('Cetak Struk Otomatis', 'Struk otomatis dicetak setelah transaksi', _printReceipt, (v) => setState(() => _printReceipt = v)),
                      _buildSwitch('Suara Notifikasi', 'Suara saat transaksi berhasil', _soundEnabled, (v) => setState(() => _soundEnabled = v)),
                      _buildSwitch('Mode Gelap', 'Tampilan gelap untuk kenyamanan mata', _darkMode, (v) => setState(() => _darkMode = v)),
                    ]),
                    const SizedBox(height: 20),
                    _buildSection('Printer', [
                      _buildPrinterSelector(),
                    ]),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDangerZone(),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          TextFormField(
            initialValue: value,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 16, color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            ),
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitch(String label, String description, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                Text(description, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }

  Widget _buildPrinterSelector() {
    final printers = ['Epson TM-T82', 'Star TSP100', 'Citizen CT-S310', 'Tidak Ada Printer'];
    return Column(
      children: List.generate(printers.length, (i) {
        return GestureDetector(
          onTap: () => setState(() => _selectedPrinter = i),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _selectedPrinter == i ? AppColors.primary.withValues(alpha: 0.07) : AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _selectedPrinter == i ? AppColors.primary : AppColors.border,
                width: _selectedPrinter == i ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  i < 3 ? Icons.print_rounded : Icons.print_disabled_rounded,
                  size: 18,
                  color: _selectedPrinter == i ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 10),
                Text(
                  printers[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: _selectedPrinter == i ? FontWeight.w600 : FontWeight.w400,
                    color: _selectedPrinter == i ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (_selectedPrinter == i)
                  const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.primary),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDangerZone() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 20),
              const SizedBox(width: 8),
              const Text('Zona Bahaya', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.danger)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.delete_sweep_rounded, size: 16),
                label: const Text('Hapus Semua Data'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: BorderSide(color: AppColors.danger.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.restore_rounded, size: 16),
                label: const Text('Reset ke Default'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.warning,
                  side: BorderSide(color: AppColors.warning.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
