import 'package:flutter/material.dart';
import 'package:flutter_application_1/src/features/help/help_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/state/auth_state.dart';
import '../../core/services/firebase_analytics_service.dart';
import '../../core/models/user_role.dart';
import '../../core/widgets/app_bottom_nav.dart';
import 'edit_profile_page.dart';
import '../notifications/notifications_page.dart'; // pastikan path benar

class ProfilePage extends ConsumerWidget {
  static const routePath = '/profile';
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final user = auth.user;
    final isProvider = user?.role == UserRole.provider;

    return AppBottomNavScaffold(
      child: CustomScrollView(
        slivers: [
          // AppBar & Profile Header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            elevation: 0,
            backgroundColor: Theme.of(context).colorScheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildProfileHeader(context, user, isProvider),
            ),
          ),

          // Body
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildUserInfoSection(context, ref, user),
                  const SizedBox(height: 16),
                  _buildStatisticsSection(context),
                  const SizedBox(height: 16),
                  if (isProvider) _buildProviderFeaturesSection(context),
                  const SizedBox(height: 16),
                  _buildGeneralSettingsSection(context, ref),
                  const SizedBox(height: 16),
                  _buildLogoutSection(context, ref),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Widgets ----------------
  Widget _buildProfileHeader(BuildContext context, user, bool isProvider) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.surface,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.3),
                      width: 3,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    backgroundImage:
                        (user?.photoUrl != null && user!.photoUrl!.isNotEmpty)
                            ? NetworkImage(user.photoUrl!)
                            : null,
                    child: (user?.photoUrl == null || user!.photoUrl!.isEmpty)
                        ? Icon(
                            Icons.person_outline,
                            size: 50,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          )
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => context.go(EditProfilePage.routePath),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.surface,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.edit,
                        size: 16,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isProvider)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.work_outline,
                        size: 14, color: Colors.blue.shade700),
                    const SizedBox(width: 6),
                    Text(
                      'Penyedia Jasa',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoSection(BuildContext context, WidgetRef ref, user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            user?.name ?? '-',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on_outlined,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  user?.locationLabel ?? 'Lokasi tidak diatur',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => context.push('${ProfilePage.routePath}/edit'),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edit Profil'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Statistik',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                  context, Icons.shopping_cart_outlined, '24', 'Transaksi'),
              _buildDivider(context),
              _buildStatItem(context, Icons.star_outline, '4.8', 'Rating'),
              _buildDivider(context),
              _buildStatItem(
                  context, Icons.thumb_up_outlined, '95%', 'Kepuasan'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) => Container(
      height: 40,
      width: 1,
      color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5));

  Widget _buildStatItem(
      BuildContext context, IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildProviderFeaturesSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.work_outline,
                  size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text('Fitur Penyedia Jasa',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          _buildProviderFeatureItem(context, Icons.manage_search_outlined,
              'Kelola Jasa', 'Kelola kategori, harga, dan deskripsi jasa', () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Membuka kelola jasa...'),
                duration: Duration(seconds: 1)));
          }),
          const SizedBox(height: 12),
          _buildProviderFeatureItem(
              context,
              Icons.reviews_outlined,
              'Ulasan & Feedback',
              'Lihat rating dan ulasan dari pelanggan', () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Membuka ulasan...'),
                duration: Duration(seconds: 1)));
          }),
          const SizedBox(height: 12),
          _buildProviderOnlineStatus(context),
        ],
      ),
    );
  }

  Widget _buildProviderOnlineStatus(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.online_prediction_outlined,
              size: 24, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status Online',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('Aktifkan untuk menerima order',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Switch(
            value: true,
            onChanged: (value) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(value
                    ? 'Status online diaktifkan'
                    : 'Status online dinonaktifkan'),
                duration: const Duration(seconds: 2),
              ));
            },
            activeColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildProviderFeatureItem(BuildContext context, IconData icon,
      String title, String subtitle, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle),
          child: Icon(icon,
              size: 20,
              color: Theme.of(context).colorScheme.onPrimaryContainer),
        ),
        title: Text(title,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        trailing: Icon(Icons.chevron_right_rounded,
            color: Theme.of(context).colorScheme.onSurfaceVariant),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildGeneralSettingsSection(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pengaturan',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildSettingItem(
            context,
            Icons.notifications_outlined,
            'Notifikasi',
            'Kelola notifikasi aplikasi',
            Icons.chevron_right_rounded,
            () async {
              try {
                final userId =
                    ref.read(authStateProvider).user?.id ?? 'unknown';
                await FirebaseAnalyticsService.logNotificationsViewEvent(
                  userId: userId,
                  notificationCount: 0,
                );
              } catch (_) {}
              context.push('${ProfilePage.routePath}/notifications');
            },
          ),
          const Divider(height: 24),
          _buildSettingItem(
              context,
              Icons.security_outlined,
              'Privasi & Keamanan',
              'Kelola keamanan akun',
              Icons.chevron_right_rounded,
              () {}),
          const Divider(height: 24),
          _buildSettingItem(context, Icons.help_outline, 'Bantuan & Dukungan',
              'Pusat bantuan dan FAQ', Icons.chevron_right_rounded, () {
            context.push('${HelpPage.routePath}');
          }),
          const Divider(height: 24),
          _buildSettingItem(
              context,
              Icons.info_outline,
              'Tentang Aplikasi',
              'Versi dan informasi aplikasi',
              Icons.chevron_right_rounded,
              () {}),
        ],
      ),
    );
  }

  Widget _buildSettingItem(BuildContext context, IconData icon, String title,
      String subtitle, IconData trailingIcon, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      title: Text(title,
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant)),
      trailing: Icon(trailingIcon,
          color: Theme.of(context).colorScheme.onSurfaceVariant),
      onTap: onTap,
    );
  }

  Widget _buildLogoutSection(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          FilledButton.icon(
            onPressed: () => _showLogoutDialog(context, ref),
            icon: const Icon(Icons.logout, size: 20),
            label: const Text('Keluar dari Aplikasi'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 8),
          Text('Versi 1.0.0',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.logout_rounded,
                color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 12),
            const Text('Keluar Aplikasi'),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari aplikasi? Anda dapat masuk kembali kapan saja.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final userId =
                    ref.read(authStateProvider).user?.id ?? 'unknown';
                await FirebaseAnalyticsService.logLogoutEvent(userId: userId);
              } catch (_) {}
              ref.read(authStateProvider.notifier).logout();
            },
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}
