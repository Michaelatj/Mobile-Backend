import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/state/auth_state.dart';
import '../../core/services/firebase_analytics_service.dart';
import 'profile_page.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  static const routePath = '/profile/edit';
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _name = TextEditingController();
  final _location = TextEditingController();
  final _photoUrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).user;
    _name.text = user?.name ?? '';
    _location.text = user?.locationLabel ?? '';
    _photoUrl.text = user?.photoUrl ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _photoUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(ProfilePage.routePath);
            }
          },
          tooltip: 'Kembali',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: cs.primaryContainer,
                  backgroundImage: (_photoUrl.text.trim().isNotEmpty)
                      ? NetworkImage(_photoUrl.text.trim())
                      : null,
                  child: _photoUrl.text.trim().isEmpty
                      ? Icon(Icons.person_outline,
                          color: cs.onPrimaryContainer, size: 40)
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Material(
                    color: cs.primary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _promptPhotoUrl,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(Icons.edit, size: 18, color: cs.onPrimary),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nama'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _location,
            decoration: const InputDecoration(labelText: 'Lokasi'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _photoUrl,
            decoration: const InputDecoration(labelText: 'Photo URL'),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () async {
              await ref.read(authStateProvider.notifier).updateProfile(
                    name: _name.text,
                    locationLabel: _location.text,
                    photoUrl: _photoUrl.text,
                  );
              // Analytics: profile edit
              try {
                final userId =
                    ref.read(authStateProvider).user?.id ?? 'unknown';
                await FirebaseAnalyticsService.logProfileEditEvent(
                  userId: userId,
                  fieldChanged: 'profile',
                  oldValue: '',
                  newValue: _name.text,
                );
              } catch (_) {}
              // navigate after frame to avoid triggering router during provider change notification
              if (!mounted) return;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) context.go(ProfilePage.routePath);
              });
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _promptPhotoUrl() async {
    // Simple helper to focus the photo url field
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tempel URL gambar ke field Photo URL')),
    );
  }
}
