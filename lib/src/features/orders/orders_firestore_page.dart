import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../core/models/order.dart';
import '../../core/state/auth_state.dart';
import '../../core/state/order_provider.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/services/firebase_analytics_nonblocking.dart';

class OrdersFirestorePage extends ConsumerWidget {
  static const routePath = '/orders-firestore';
  const OrdersFirestorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider.select((value) => value.user));
    
    if (user == null) {
      return AppBottomNavScaffold(
        child: Scaffold(
          body: const Center(child: Text('Silakan login terlebih dahulu')),
        ),
      );
    }

    final ordersAsync = ref.watch(userOrdersProvider(user.id));

    return AppBottomNavScaffold(
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              pinned: true,
              title: const Text('Pesanan Saya'),
              centerTitle: true,
              elevation: 0,
              backgroundColor: Theme.of(context).colorScheme.surface,
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (ordersAsync.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (ordersAsync.hasError) {
                      return Center(child: Text('Error: ${ordersAsync.error}'));
                    }
                    
                    final orders = ordersAsync.value ?? [];
                    if (index >= orders.length) {
                      return null;
                    }
                    
                    final order = orders[index];
                    return _OrderCard(
                      order: order,
                      onCancel: () => _cancelOrder(ref, order),
                    );
                  },
                  childCount: ordersAsync.isLoading ? 1 : (ordersAsync.value?.length ?? 0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancelOrder(WidgetRef ref, Order order) async {
    final user = ref.read(authStateProvider).user;
    
    // Fire-and-forget analytics
    FirebaseAnalyticsNonBlocking.logBookingCanceledEvent(
      userId: user?.id ?? 'unknown',
      bookingId: order.id,
      providerId: order.serviceProviderId ?? 'unknown',
      cancelReason: 'user_initiated',
    );

    // Update order status to cancelled
    await ref.read(orderProvider(order.id).notifier).updateStatus(order.id, OrderStatus.cancelled);
  }
}

class _OrderCard extends ConsumerWidget {
  final Order order;
  final VoidCallback onCancel;

  const _OrderCard({required this.order, required this.onCancel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Color statusColor;
    String statusText;
    
    switch (order.status) {
      case OrderStatus.pending:
        statusColor = Colors.orange;
        statusText = 'Menunggu';
      case OrderStatus.confirmed:
        statusColor = Colors.blue;
        statusText = 'Dikonfirmasi';
      case OrderStatus.inProgress:
        statusColor = Colors.yellow;
        statusText = 'Berlangsung';
      case OrderStatus.completed:
        statusColor = Colors.green;
        statusText = 'Selesai';
      case OrderStatus.cancelled:
        statusColor = Colors.red;
        statusText = 'Dibatalkan';
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with ID & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.receipt_long_rounded,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'ORD-${order.id.substring(0, math.min(8, order.id.length))}',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.serviceName ?? 'Layanan',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor, width: 1),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Service Provider Info
            if (order.serviceProviderName != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.business_rounded,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      order.serviceProviderName!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Date & Time
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  order.createdAt != null
                      ? DateFormat('dd MMM yyyy', 'id_ID')
                          .format(order.createdAt!)
                      : '-',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  order.createdAt != null
                      ? DateFormat('HH:mm', 'id_ID').format(order.createdAt!)
                      : '-',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Total Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Text(
                  NumberFormat.currency(
                    locale: 'id_ID',
                    symbol: 'Rp ',
                    decimalDigits: 0,
                  ).format(order.totalAmount),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),

            // Action buttons based on status
            const SizedBox(height: 12),
            if (order.status == OrderStatus.pending) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCancel,
                      child: const Text('Batalkan'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        // Confirm order action
                        ref.read(orderProvider(order.id).notifier)
                            .updateStatus(order.id, OrderStatus.confirmed);
                      },
                      child: const Text('Konfirmasi'),
                    ),
                  ),
                ],
              ),
            ] else if (order.status == OrderStatus.confirmed) ...[
              Text(
                'Pesanan telah dikonfirmasi, sedang menunggu pelaksanaan',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}