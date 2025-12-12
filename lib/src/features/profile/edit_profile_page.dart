import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/state/auth_state.dart';
import '../../core/services/firebase_analytics_service.dart';
import '../../core/services/user_api_service.dart';
import 'profile_page.dart';
import '../../core/services/firestore_service.dart';

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
              final user = ref.read(authStateProvider).user;
              if (user == null) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tidak login')),
                );
                return;
              }

              final isLoading = ValueNotifier<bool>(false);

              // Perform all async operations before updating state
              try {
                isLoading.value = true;

               // 1. UPDATE KE FIRESTORE 🔥
                await FirestoreService.updateUserProfile(
                  uid: user.id,
                  name: _name.text,
                  locationLabel: _location.text.trim().isEmpty ? null : _location.text,
                  photoUrl: _photoUrl.text.trim().isEmpty ? null : _photoUrl.text,
                );

                // 2. Update Firebase Auth Profile (untuk nama & foto bawaan)
                final firebaseUser = FirebaseAuth.instance.currentUser;
                if (firebaseUser != null) {
                  await firebaseUser.updateDisplayName(_name.text);
                  if (_photoUrl.text.trim().isNotEmpty) {
                    await firebaseUser.updatePhotoURL(_photoUrl.text.trim());
                  }
                }

                // 3. Update local state Riverpod agar UI langsung berubah
                await ref.read(authStateProvider.notifier).updateProfile(
                      name: _name.text,
                      locationLabel: _location.text.trim().isEmpty ? null : _location.text,
                      photoUrl: _photoUrl.text.trim().isEmpty ? null : _photoUrl.text,
                    );

                // 4. Log analytics (non-blocking, so don't await)
                try {
                  await FirebaseAnalyticsService.logProfileEditEvent(
                    userId: user.id,
                    fieldChanged: 'profile',
                    oldValue: user.name,
                    newValue: _name.text,
                  );
                } catch (_) {
                  // silently ignore analytics errors
                }

                if (!mounted) return;

                // 5. Show success and navigate
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profil berhasil diperbarui')),
                );

                // navigate after frame to avoid triggering router during provider change notification
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) context.go(ProfilePage.routePath);
                });
              } catch (e) {
                if (!mounted) return;
                debugPrint('ERROR: Failed to update profile: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gagal perbarui profil: $e')),
                );
              } finally {
                isLoading.value = false;
              }
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
