import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/user_role.dart';
import '../../core/state/auth_state.dart';
import '../profile/profile_setup_page.dart';

class RoleSelectionPage extends ConsumerWidget {
  static const routePath = '/auth/role';
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(authStateProvider.notifier);

    Widget card(String title, String desc, IconData icon, UserRole role) {
      return Card(
        child: ListTile(
          leading: Icon(icon),
          title: Text(title),
          subtitle: Text(desc),
          onTap: () {
            ctrl.chooseRole(role);
            context.go(ProfileSetupPage.routePath);
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Pilih Peran')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            card('Saya Butuh Jasa', 'Cari dan pesan penyedia jasa.', Icons.person_search_outlined, UserRole.customer),
            card('Saya Penyedia Jasa', 'Terima pesanan dan kelola layanan.', Icons.home_repair_service_outlined, UserRole.provider),
          ],
        ),
      ),
    );
  }
}
