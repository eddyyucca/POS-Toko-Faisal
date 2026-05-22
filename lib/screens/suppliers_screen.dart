import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/supplier.dart';
import '../models/purchase.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppProvider>(context, listen: false).loadSuppliers();
    });
  }

  void _showSupplierForm({Supplier? supplier}) {
    final nameCtrl = TextEditingController(text: supplier?.name ?? '');
    final phoneCtrl = TextEditingController(text: supplier?.phone ?? '');
    final addressCtrl = TextEditingController(text: supplier?.address ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(supplier == null ? 'Tambah Supplier' : 'Edit Supplier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Supplier', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'No. HP / Telepon', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Alamat', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              final provider = Provider.of<AppProvider>(context, listen: false);
              if (supplier == null) {
                provider.addSupplier(Supplier(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameCtrl.text,
                  phone: phoneCtrl.text,
                  address: addressCtrl.text,
                ));
              } else {
                provider.updateSupplier(Supplier(
                  id: supplier.id,
                  name: nameCtrl.text,
                  phone: phoneCtrl.text,
                  address: addressCtrl.text,
                ));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _deleteSupplier(Supplier supplier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Supplier'),
        content: Text('Anda yakin ingin menghapus "${supplier.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Provider.of<AppProvider>(context, listen: false).deleteSupplier(supplier.id);
              Navigator.pop(ctx);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPurchaseDialog(Supplier supplier) {
    // A simplified purchase dialog where user types total cost and selects one product to restock
    final totalCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    Product? selectedProduct;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateSB) {
          final provider = Provider.of<AppProvider>(context, listen: false);
          return AlertDialog(
            title: Text('Kulakan dari ${supplier.name}'),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pilih Produk yang Masuk Gudang:'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Product>(
                    value: selectedProduct,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    hint: const Text('Pilih Produk'),
                    items: provider.products.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                    onChanged: (v) => setStateSB(() => selectedProduct = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Jumlah Kuantitas (Qty)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: totalCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Total Harga Kulakan (Rp)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  const Text('Catatan: Transaksi ini akan langsung menambah Stok Gudang produk yang dipilih.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
              ElevatedButton(
                onPressed: () {
                  if (selectedProduct != null && qtyCtrl.text.isNotEmpty && totalCtrl.text.isNotEmpty) {
                    final qty = int.tryParse(qtyCtrl.text) ?? 0;
                    final total = double.tryParse(totalCtrl.text) ?? 0;
                    
                    if (qty > 0) {
                      final purchaseId = DateTime.now().millisecondsSinceEpoch.toString();
                      final purchase = Purchase(
                        id: purchaseId,
                        date: DateTime.now().toIso8601String(),
                        supplierId: supplier.id,
                        total: total,
                        notes: 'Restock via UI',
                        userId: provider.currentUser?.id ?? '1',
                      );
                      
                      final item = PurchaseItem(
                        id: DateTime.now().microsecondsSinceEpoch.toString(),
                        purchaseId: purchaseId,
                        productId: selectedProduct!.id,
                        qty: qty,
                        costPrice: total / qty,
                      );

                      provider.processPurchase(purchase, [item]);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pembelian berhasil! Stok Gudang bertambah.')));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                child: const Text('Konfirmasi Pembelian'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final suppliers = provider.suppliersList;
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Manajemen Supplier', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      SizedBox(height: 4),
                      Text('Kelola pemasok dan catat pembelian', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showSupplierForm(),
                    icon: const Icon(Icons.add_business_rounded, size: 18),
                    label: const Text('Tambah Supplier'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ListView.separated(
                    itemCount: suppliers.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (context, index) {
                      final s = suppliers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: const Icon(Icons.local_shipping_rounded, color: AppColors.primary),
                        ),
                        title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${s.phone} • ${s.address}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _showPurchaseDialog(s),
                              icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 16),
                              label: const Text('Kulakan'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, color: AppColors.primary, size: 20),
                              onPressed: () => _showSupplierForm(supplier: s),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_rounded, color: AppColors.danger, size: 20),
                              onPressed: () => _deleteSupplier(s),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
