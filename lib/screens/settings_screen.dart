import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Text controllers
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _taxPercCtrl = TextEditingController();
  final TextEditingController _footerCtrl = TextEditingController();

  // Switch states
  bool _printReceipt = true;
  bool _taxEnabled = true;
  bool _soundEnabled = false;

  // Printer selection
  int _selectedPrinter = 0;

  // Loading / saving state
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFromProvider();
    });
  }

  void _loadFromProvider() {
    final provider = Provider.of<AppProvider>(context, listen: false);
    _nameCtrl.text = provider.getSetting('store_name', defaultValue: 'Toko Faisal');
    _addressCtrl.text = provider.getSetting('store_address', defaultValue: '');
    _phoneCtrl.text = provider.getSetting('store_phone', defaultValue: '');
    _emailCtrl.text = provider.getSetting('store_email', defaultValue: '');
    _taxPercCtrl.text = provider.getSetting('tax_percent', defaultValue: '11');
    _footerCtrl.text = provider.getSetting('receipt_footer', defaultValue: '');
    setState(() {
      _taxEnabled = provider.getSetting('tax_enabled', defaultValue: 'true') == 'true';
      _printReceipt = provider.getSetting('print_receipt', defaultValue: 'true') == 'true';
      _soundEnabled = provider.getSetting('sound_enabled', defaultValue: 'false') == 'true';
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _taxPercCtrl.dispose();
    _footerCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveAllSettings() async {
    setState(() => _isSaving = true);
    final provider = Provider.of<AppProvider>(context, listen: false);
    try {
      await provider.saveSettings({
        'store_name': _nameCtrl.text.trim(),
        'store_address': _addressCtrl.text.trim(),
        'store_phone': _phoneCtrl.text.trim(),
        'store_email': _emailCtrl.text.trim(),
        'tax_percent': _taxPercCtrl.text.trim(),
        'receipt_footer': _footerCtrl.text.trim(),
        'tax_enabled': _taxEnabled.toString(),
        'print_receipt': _printReceipt.toString(),
        'sound_enabled': _soundEnabled.toString(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Text('Pengaturan berhasil disimpan!', style: TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan pengaturan: $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pengaturan',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Konfigurasi aplikasi POS Anda',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              // Save button in header area
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveAllSettings,
                icon: _isSaving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_rounded, size: 16),
                label: Text(_isSaving ? 'Menyimpan...' : 'Simpan Pengaturan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  elevation: 0,
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column
              Expanded(
                child: Column(
                  children: [
                    _buildSection('Informasi Toko', [
                      _buildTextField('Nama Toko', 'cth. Toko Faisal', Icons.store_rounded, _nameCtrl),
                      _buildTextField('Alamat', 'cth. Jl. Merdeka No. 10, Jakarta', Icons.location_on_rounded, _addressCtrl),
                      _buildTextField('No. Telepon', 'cth. +62 812 3456 7890', Icons.phone_rounded, _phoneCtrl),
                      _buildTextField('Email', 'cth. toko@email.com', Icons.email_rounded, _emailCtrl),
                    ]),
                    const SizedBox(height: 20),
                    _buildSection('Konfigurasi Pajak', [
                      _buildSwitch(
                        'Aktifkan PPN',
                        'Pajak diterapkan pada setiap transaksi',
                        _taxEnabled,
                        (v) {
                          setState(() => _taxEnabled = v);
                          Provider.of<AppProvider>(context, listen: false)
                              .saveSetting('tax_enabled', v.toString());
                        },
                      ),
                      _buildTextField('Persentase Pajak (%)', 'cth. 11', Icons.percent_rounded, _taxPercCtrl,
                          keyboardType: TextInputType.number),
                    ]),
                    const SizedBox(height: 20),
                    _buildSection('Struk & Footer', [
                      _buildMultilineTextField(
                        'Footer Struk',
                        'cth. Terima kasih telah berbelanja!',
                        Icons.receipt_rounded,
                        _footerCtrl,
                      ),
                    ]),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Right column
              Expanded(
                child: Column(
                  children: [
                    _buildSection('Preferensi', [
                      _buildSwitch(
                        'Cetak Struk Otomatis',
                        'Struk otomatis dicetak setelah transaksi',
                        _printReceipt,
                        (v) {
                          setState(() => _printReceipt = v);
                          Provider.of<AppProvider>(context, listen: false)
                              .saveSetting('print_receipt', v.toString());
                        },
                      ),
                      _buildSwitch(
                        'Suara Notifikasi',
                        'Suara saat transaksi berhasil',
                        _soundEnabled,
                        (v) {
                          setState(() => _soundEnabled = v);
                          Provider.of<AppProvider>(context, listen: false)
                              .saveSetting('sound_enabled', v.toString());
                        },
                      ),
                    ]),
                    const SizedBox(height: 20),
                    _buildSection('Printer', [
                      _buildPrinterSelector(),
                    ]),
                    const SizedBox(height: 20),
                    // Info card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Perubahan pada pengaturan akan aktif setelah disimpan. Klik "Simpan Pengaturan" untuk menyimpan semua perubahan.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
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
          const SizedBox(height: 20),
          // Save button at bottom
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveAllSettings,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_rounded, size: 18),
              label: Text(
                _isSaving ? 'Menyimpan Pengaturan...' : 'Simpan Pengaturan',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
            ),
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
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String hint,
    IconData icon,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              prefixIcon: Icon(icon, size: 16, color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultilineTextField(
    String label,
    String hint,
    IconData icon,
    TextEditingController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            maxLines: 3,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Icon(icon, size: 16, color: AppColors.textSecondary),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 48),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitch(
    String label,
    String description,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
                ),
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
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 20),
              SizedBox(width: 8),
              Text(
                'Zona Bahaya',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.danger),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Tindakan berikut tidak dapat dibatalkan. Harap berhati-hati.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _showDangerConfirmDialog(
                  title: 'Hapus Semua Data',
                  message: 'Semua data transaksi, produk, dan pengguna akan dihapus secara permanen. Tindakan ini tidak dapat dibatalkan.',
                  onConfirm: () {
                    // TODO: implement clear all data
                  },
                ),
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
                onPressed: () => _showDangerConfirmDialog(
                  title: 'Reset ke Default',
                  message: 'Semua pengaturan akan dikembalikan ke nilai awal. Data transaksi tidak akan terpengaruh.',
                  onConfirm: () {
                    // Reset to defaults
                    setState(() {
                      _nameCtrl.text = 'Toko Faisal';
                      _addressCtrl.text = '';
                      _phoneCtrl.text = '';
                      _emailCtrl.text = '';
                      _taxPercCtrl.text = '11';
                      _footerCtrl.text = '';
                      _taxEnabled = true;
                      _printReceipt = true;
                      _soundEnabled = false;
                    });
                  },
                ),
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

  void _showDangerConfirmDialog({
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 22),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Ya, Lanjutkan'),
          ),
        ],
      ),
    );
  }
}
