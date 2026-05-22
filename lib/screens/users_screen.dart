import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/user.dart';
import '../theme/app_theme.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppProvider>(context, listen: false).loadUsers();
    });
  }

  void _showUserForm({User? user}) {
    final usernameCtrl = TextEditingController(text: user?.username ?? '');
    final passwordCtrl = TextEditingController(text: user?.password ?? '');
    String role = user?.role ?? 'Kasir';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateSB) => AlertDialog(
          title: Text(user == null ? 'Tambah Pengguna' : 'Edit Pengguna'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameCtrl,
                decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: role,
                decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
                items: ['Admin', 'Kasir'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (v) => setStateSB(() => role = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                final provider = Provider.of<AppProvider>(context, listen: false);
                if (user == null) {
                  provider.addUser(User(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    username: usernameCtrl.text,
                    password: passwordCtrl.text,
                    role: role,
                  ));
                } else {
                  provider.updateUser(User(
                    id: user.id,
                    username: usernameCtrl.text,
                    password: passwordCtrl.text,
                    role: role,
                  ));
                }
                Navigator.pop(ctx);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteUser(User user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Pengguna'),
        content: Text('Anda yakin ingin menghapus "${user.username}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Provider.of<AppProvider>(context, listen: false).deleteUser(user.id);
              Navigator.pop(ctx);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final users = provider.usersList;
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
                      Text('Manajemen Pengguna', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      SizedBox(height: 4),
                      Text('Kelola akses kasir dan admin', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showUserForm(),
                    icon: const Icon(Icons.person_add_rounded, size: 18),
                    label: const Text('Tambah Pengguna'),
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
                    itemCount: users.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (context, index) {
                      final u = users[index];
                      final isCurrent = provider.currentUser?.id == u.id;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: u.role == 'Admin' ? AppColors.primary : AppColors.primary,
                          child: Icon(u.role == 'Admin' ? Icons.admin_panel_settings : Icons.person, color: Colors.white),
                        ),
                        title: Text(u.username, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(u.role),
                        trailing: isCurrent
                            ? const Chip(label: Text('Anda', style: TextStyle(fontSize: 11)), backgroundColor: AppColors.background)
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_rounded, color: AppColors.primary, size: 20),
                                    onPressed: () => _showUserForm(user: u),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_rounded, color: AppColors.danger, size: 20),
                                    onPressed: () => _deleteUser(u),
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
