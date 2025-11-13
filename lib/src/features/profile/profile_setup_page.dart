import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/state/auth_state.dart';
import '../../core/models/user_role.dart';
import '../home/home_page.dart';

class ProfileSetupPage extends ConsumerStatefulWidget {
  static const routePath = '/profile/setup';
  const ProfileSetupPage({super.key});

  @override
  ConsumerState<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends ConsumerState<ProfileSetupPage> {
  final _name = TextEditingController();
  final _location = TextEditingController();
  final _category = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _category.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final role = auth.user?.role ?? UserRole.customer;

    return Scaffold(
      appBar: AppBar(title: const Text('Lengkapi Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nama')),
          const SizedBox(height: 12),
          TextFormField(
              controller: _location,
              decoration: const InputDecoration(labelText: 'Lokasi')),
          if (role == UserRole.provider) ...[
            const SizedBox(height: 12),
            TextFormField(
                controller: _category,
                decoration: const InputDecoration(labelText: 'Kategori Jasa')),
            const SizedBox(height: 12),
            OutlinedButton(
                onPressed: () {},
                child: const Text('Upload KTP / Selfie (placeholder)')),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              // TODO: Save profile to backend
              context.go(HomePage.routePath);
            },
            child: const Text('Selesai'),
          )
        ],
      ),
    );
  }
}
