import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/models/service_provider.dart';
import '../../core/models/booking.dart';
import '../../core/models/message.dart';
import '../../core/state/providers.dart';
import '../../core/state/auth_state.dart';
import '../../core/database/booking_dao.dart';
import '../../core/database/message_dao.dart';
import '../reviews/review_section.dart';
import '../orders/orders_page.dart';
import '../home/home_page.dart';

class ProviderDetailPage extends ConsumerWidget {
  static const routeBase = '/provider/detail';
  static const routePath = '$routeBase/:id';
  final String providerId;

  const ProviderDetailPage({super.key, required this.providerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providerAsync = ref.watch(providerByIdProvider(providerId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Penyedia'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(HomePage.routePath);
            }
          },
          tooltip: 'Kembali',
        ),
      ),
      body: providerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Gagal memuat: $e')),
        data: (sp) {
          if (sp == null)
            return const Center(child: Text('Penyedia tidak ditemukan'));

          final user = ref.read(authStateProvider).user;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Header(provider: sp),
              const SizedBox(height: 16),
              Text(
                'Tentang',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(sp.description),
              const SizedBox(height: 24),

              // Use single ReviewSection (contains header, add/edit/delete)
              ReviewSection(
                providerId: sp.id,
                userId: user?.id,
              ),

              const SizedBox(height: 24),
            ],
          );
        },
      ),
      bottomNavigationBar: providerAsync.when(
        data: (sp) => sp == null
            ? null
            : Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2))
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mulai dari',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant),
                            ),
                            Text(
                              'Rp ${NumberFormat('#,###', 'id_ID').format(sp.priceFrom)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Chat / Message button -> open dialog then save via MessageDao
                      OutlinedButton(
                        onPressed: () async {
                          final controller = TextEditingController();
                          final text = await showDialog<String>(
                            context: context,
                            builder: (ctx) {
                              return AlertDialog(
                                title: const Text('Kirim Pesan'),
                                content: TextField(
                                  controller: controller,
                                  decoration: const InputDecoration(
                                      hintText:
                                          'Tulis pesan untuk penyedia jasa...'),
                                  maxLines: 4,
                                ),
                                actions: [
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(null),
                                      child: const Text('Batal')),
                                  FilledButton(
                                      onPressed: () => Navigator.of(ctx)
                                          .pop(controller.text.trim()),
                                      child: const Text('Kirim')),
                                ],
                              );
                            },
                          );
                          if (text == null || text.isEmpty) return;

                          final user = ref.read(authStateProvider).user;
                          final message = Message(
                            id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
                            providerId: sp.id,
                            userId: user?.id ?? 'guest',
                            content: text,
                            createdAt: DateTime.now(),
                          );

                          try {
                            await MessageDao.insertMessage(message);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Pesan terkirim dan disimpan')));
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text('Gagal mengirim pesan: $e')));
                            }
                          }
                        },
                        child: const Icon(Icons.chat_bubble_outline),
                      ),
                      const SizedBox(width: 8),

                      // Pesan button -> navigate to booking form (preferred flow)
                     FilledButton.icon(
  onPressed: () {
    context.push(
      '/provider/detail/${sp.id}/book',
      extra: {
        'providerId': sp.id,
        'providerName': sp.name,
        'priceFrom': sp.priceFrom, // HARUS DIKIRIM!
      },
    );
  },
  icon: const Icon(Icons.shopping_cart_checkout, size: 20),
  label: const Text('Pesan'),
),
                    ],
                  ),
                ),
              ),
        loading: () => null,
        error: (e, st) => null,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final ServiceProvider provider;
  const _Header({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
              color: Theme.of(context)
                  .colorScheme
                  .outlineVariant
                  .withOpacity(0.5))),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.home_repair_service_rounded,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 32),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(provider.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.category_rounded,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(provider.category),
                      const SizedBox(width: 12),
                      const Icon(Icons.star_rounded,
                          size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(provider.rating.toStringAsFixed(1)),
                    ]),
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.place_rounded,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 4),
                      Text('${provider.distanceKm.toStringAsFixed(1)} km'),
                    ]),
                  ]),
            ),
          ],
        ),
      ),
    );
  }
}
