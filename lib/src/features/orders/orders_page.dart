import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../core/state/auth_state.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/models/booking.dart'; // use Booking + status
import '../../core/models/service_provider.dart'; // to map provider infoS
import '../../core/database/booking_dao.dart';
import '../../core/database/provider_dao.dart';
import '../../core/services/firebase_analytics_nonblocking.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Supaya kenal tipe data 'Timestamp'
import 'package:firebase_auth/firebase_auth.dart'; // Supaya kenal 'FirebaseAuth'



class OrdersPage extends ConsumerStatefulWidget {
  static const routePath = '/orders';
  const OrdersPage({super.key});

  @override
  ConsumerState<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends ConsumerState<OrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;
  bool _localeInitialized = false;

  late Future<List<OrderItem>> _futureOrders;

  @override
  void initState() {
    super.initState();
    _initializeLocale();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(() => _selectedTab = _tabController.index);
    });
    _futureOrders = _loadOrders();
  }

  Future<void> _initializeLocale() async {
    await initializeDateFormatting('id_ID', null);
    setState(() {
      _localeInitialized = true;
    });
  }

Future<List<OrderItem>> _loadOrders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("❌ User belum login, tidak bisa ambil order.");
      return [];
    }

    print("🔍 Mengambil order untuk User ID: ${user.uid}...");

    try {
      // PENTING: Perhatikan 'orderBy' dan 'where'
      // Jika kamu pakai filter + sort, Firebase butuh INDEX.
      final snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          //.orderBy('date', descending: true) // 👈 COBA KOMENTAR DULU BARIS INI
          .get();

      print("✅ Ditemukan ${snapshot.docs.length} dokumen di Firestore.");

      final items = <OrderItem>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        print("   -> Order ID: ${doc.id}, Status: ${data['status']}");

        // Parsing data (Safety check)
        final dateTimestamp = data['date'] as Timestamp?;
        final date = dateTimestamp?.toDate() ?? DateTime.now();
        
        // Convert status string ke Enum
        OrderStatus statusEnum = OrderStatus.pending;
        final statusStr = data['status'] as String? ?? 'pending';
        if (statusStr == 'inProgress') statusEnum = OrderStatus.inProgress;
        else if (statusStr == 'completed') statusEnum = OrderStatus.completed;
        else if (statusStr == 'cancelled') statusEnum = OrderStatus.cancelled;

        items.add(
          OrderItem(
            id: doc.id,
            invoiceNumber: data['invoiceNumber'] ?? 'INV-???',
            providerName: data['providerName'] ?? 'Jasa',
            category: data['category'] ?? 'Umum',
            status: statusEnum,
            date: date,
            time: DateFormat('HH:mm').format(date),
            totalAmount: (data['totalAmount'] as num?)?.toInt() ?? 0,
            services: List<String>.from(data['services'] ?? []),
            paymentMethod: data['paymentMethod'] ?? '-',
            rating: (data['rating'] as num?)?.toInt(),
          ),
        );
      }
      return items;
      
    } catch (e) {
      print("🔥 ERROR SAAT AMBIL ORDERS: $e");
      return [];
    }
  }

  OrderStatus _mapStatus(BookingStatus s) {
    switch (s) {
      case BookingStatus.pending:
        return OrderStatus.pending;
      case BookingStatus.inProgress:
        return OrderStatus.inProgress;
      case BookingStatus.completed:
        return OrderStatus.completed;
      case BookingStatus.cancelled:
        return OrderStatus.cancelled;
    }
  }

  Future<void> _cancelOrder(OrderItem order) async {
    // Ambil user untuk analytics (opsional)
    final user = FirebaseAuth.instance.currentUser;

    // 1. Fire-and-forget analytics (non-blocking) - TETAP KITA PERTAHANKAN ✅
    FirebaseAnalyticsNonBlocking.logBookingCanceledEvent(
      userId: user?.uid ?? 'unknown',
      bookingId: order.id,
      providerId: order.id, 
      cancelReason: 'user_initiated',
    );

    try {
      // 2. UPDATE STATUS DI FIRESTORE ☁️ (Bagian Kuncinya!)
      // Kita panggil fungsi updateOrderStatus yang sudah kita buat di FirestoreService
      await FirestoreService.updateOrderStatus(order.id, 'cancelled');

      if (!mounted) return;

      // 3. REFRESH UI 🔄
      // Panggil ulang _loadOrders() supaya aplikasi mengambil data terbaru dari Firestore
      // Karena statusnya sudah 'cancelled', dia akan otomatis pindah ke tab "Dibatalkan"
      setState(() {
        _futureOrders = _loadOrders();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pesanan berhasil dibatalkan')),
      );
      
    } catch (e) {
      print("Gagal cancel: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membatalkan: $e')),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<OrderItem> _filtered(List<OrderItem> all) {
    if (_selectedTab == 0) return all;
    final status = OrderStatus.values[_selectedTab - 1];
    return all.where((o) => o.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (!_localeInitialized) {
      return AppBottomNavScaffold(
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
          body: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return AppBottomNavScaffold(
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              floating: true,
              pinned: true,
              title: const Text('Pesanan Saya'),
              centerTitle: true,
              elevation: 0,
              backgroundColor: Theme.of(context).colorScheme.surface,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  color: Theme.of(context).colorScheme.surface,
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    indicatorColor: Theme.of(context).colorScheme.primary,
                    labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor:
                        Theme.of(context).colorScheme.onSurfaceVariant,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    tabs: const [
                      Tab(text: 'Semua'),
                      Tab(text: 'Menunggu'),
                      Tab(text: 'Berlangsung'),
                      Tab(text: 'Selesai'),
                      Tab(text: 'Dibatalkan'),
                    ],
                  ),
                ),
              ),
            ),
          ],
          body: FutureBuilder<List<OrderItem>>(
            future: _futureOrders,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final all = snapshot.data ?? const <OrderItem>[];
              final list = _filtered(all);
              if (list.isEmpty) {
                return _buildEmptyState();
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, index) {
                  return _OrderCard(
                    order: list[index],
                    onRequestCancel: () => _cancelOrder(list[index]),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;

    switch (_selectedTab) {
      case 1:
        message = 'Tidak ada pesanan menunggu';
        icon = Icons.schedule_rounded;
        break;
      case 2:
        message = 'Tidak ada pesanan berlangsung';
        icon = Icons.sync_rounded;
        break;
      case 3:
        message = 'Tidak ada pesanan selesai';
        icon = Icons.check_circle_rounded;
        break;
      case 4:
        message = 'Tidak ada pesanan dibatalkan';
        icon = Icons.cancel_rounded;
        break;
      default:
        message = 'Belum ada pesanan';
        icon = Icons.inbox_rounded;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pesanan Anda akan muncul di sini',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderItem order;
  final VoidCallback onRequestCancel;

  const _OrderCard({required this.order, required this.onRequestCancel});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showOrderDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Invoice & Status
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
                              order.invoiceNumber,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.providerName,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusChip(context),
                ],
              ),
              const SizedBox(height: 12),

              // Services & Category
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withOpacity(0.5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.category_rounded,
                                size: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                order.category,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      order.services.join(' • '),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

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
                    DateFormat('dd MMM yyyy', 'id_ID').format(order.date),
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
                    order.time,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),

              // Progress Bar (for In Progress)
              if (order.status == OrderStatus.inProgress) ...[
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress Pengerjaan',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        Text(
                          '${(order.progress * 100).toInt()}%',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: order.progress,
                        minHeight: 6,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // Rating (for Completed)
              if (order.status == OrderStatus.completed &&
                  order.rating != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    ...List.generate(
                      5,
                      (index) => Icon(
                        index < order.rating!
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 16,
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Rating Anda',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Footer: Price & Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Pembayaran',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Rp ${NumberFormat('#,###', 'id_ID').format(order.totalAmount)}',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  _buildActionButton(context),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    Color bgColor;
    Color textColor;
    IconData icon;
    String label;

    switch (order.status) {
      case OrderStatus.pending:
        bgColor = Colors.orange.withOpacity(0.15);
        textColor = Colors.orange.shade700;
        icon = Icons.schedule_rounded;
        label = 'Menunggu';
        break;
      case OrderStatus.inProgress:
        bgColor = Colors.blue.withOpacity(0.15);
        textColor = Colors.blue.shade700;
        icon = Icons.sync_rounded;
        label = 'Berlangsung';
        break;
      case OrderStatus.completed:
        bgColor = Colors.green.withOpacity(0.15);
        textColor = Colors.green.shade700;
        icon = Icons.check_circle_rounded;
        label = 'Selesai';
        break;
      case OrderStatus.cancelled:
        bgColor = Colors.red.withOpacity(0.15);
        textColor = Colors.red.shade700;
        icon = Icons.cancel_rounded;
        label = 'Dibatalkan';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    switch (order.status) {
      case OrderStatus.pending:
        return OutlinedButton.icon(
          onPressed: () => _showOrderDetail(context),
          icon: const Icon(Icons.info_outline, size: 16),
          label: const Text('Detail'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      case OrderStatus.inProgress:
        return FilledButton.tonalIcon(
          onPressed: () => _showOrderDetail(context),
          icon: const Icon(Icons.visibility_outlined, size: 16),
          label: const Text('Lacak'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      case OrderStatus.completed:
        return FilledButton.icon(
          onPressed: () => _downloadInvoice(context),
          icon: const Icon(Icons.download_rounded, size: 16),
          label: const Text('Invoice'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      case OrderStatus.cancelled:
        return OutlinedButton.icon(
          onPressed: () => _showOrderDetail(context),
          icon: const Icon(Icons.info_outline, size: 16),
          label: const Text('Detail'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
    }
  }

  void _showOrderDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _OrderDetailSheet(order: order, onRequestCancel: onRequestCancel), //
    );
  }

  void _downloadInvoice(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.download_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Text('Mengunduh invoice ${order.invoiceNumber}...'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _OrderDetailSheet extends StatelessWidget {
  final OrderItem order;
  final VoidCallback onRequestCancel;

  const _OrderDetailSheet({required this.order, required this.onRequestCancel});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detail Pesanan',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.invoiceNumber,
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(16),
                children: [
                  // Status Banner
                  _buildStatusBanner(context),
                  const SizedBox(height: 20),

                  // Provider Info
                  _buildSection(
                    context,
                    'Penyedia Jasa',
                    Icons.person_rounded,
                    [
                      _buildDetailRow(context, 'Nama', order.providerName),
                      _buildDetailRow(context, 'Kategori', order.category),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Service Info
                  _buildSection(
                    context,
                    'Informasi Layanan',
                    Icons.build_circle_rounded,
                    [
                      _buildDetailRow(
                        context,
                        'Tanggal',
                        DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
                            .format(order.date),
                      ),
                      _buildDetailRow(context, 'Waktu', order.time),
                      _buildDetailRow(
                        context,
                        'Layanan',
                        order.services.join(', '),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Payment Info
                  _buildSection(
                    context,
                    'Pembayaran',
                    Icons.payment_rounded,
                    [
                      _buildDetailRow(
                        context,
                        'Metode',
                        order.paymentMethod,
                      ),
                      _buildDetailRow(
                        context,
                        'Total',
                        'Rp ${NumberFormat('#,###', 'id_ID').format(order.totalAmount)}',
                        valueStyle:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                      ),
                      if (order.status != OrderStatus.cancelled)
                        _buildDetailRow(
                          context,
                          'Status Escrow',
                          order.status == OrderStatus.completed
                              ? 'Dana Diteruskan'
                              : 'Dana Ditahan',
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  _buildActionButtons(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner(BuildContext context) {
    Color bgColor;
    Color textColor;
    IconData icon;
    String title;
    String subtitle;

    switch (order.status) {
      case OrderStatus.pending:
        bgColor = Colors.orange.withOpacity(0.15);
        textColor = Colors.orange.shade700;
        icon = Icons.schedule_rounded;
        title = 'Menunggu Konfirmasi';
        subtitle = 'Penyedia jasa akan segera mengonfirmasi pesanan Anda';
        break;
      case OrderStatus.inProgress:
        bgColor = Colors.blue.withOpacity(0.15);
        textColor = Colors.blue.shade700;
        icon = Icons.sync_rounded;
        title = 'Dalam Proses';
        subtitle = 'Penyedia jasa sedang mengerjakan pesanan Anda';
        break;
      case OrderStatus.completed:
        bgColor = Colors.green.withOpacity(0.15);
        textColor = Colors.green.shade700;
        icon = Icons.check_circle_rounded;
        title = 'Selesai';
        subtitle = 'Pesanan telah selesai dikerjakan';
        break;
      case OrderStatus.cancelled:
        bgColor = Colors.red.withOpacity(0.15);
        textColor = Colors.red.shade700;
        icon = Icons.cancel_rounded;
        title = 'Dibatalkan';
        subtitle = 'Pesanan telah dibatalkan';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 32, color: textColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: textColor.withOpacity(0.8),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon,
                  size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    TextStyle? valueStyle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: valueStyle ??
                  Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (order.status == OrderStatus.pending) ...[
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Menghubungi penyedia jasa...'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Hubungi Penyedia'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () {
              _showCancelDialog(context);
            },
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Batalkan Pesanan'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
        if (order.status == OrderStatus.inProgress) ...[
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showComplaintDialog(context);
            },
            icon: const Icon(Icons.report_problem_outlined),
            label: const Text('Ajukan Komplain'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Membuka chat...'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Hubungi Penyedia'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
        if (order.status == OrderStatus.completed) ...[
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.download_rounded, color: Colors.white),
                      const SizedBox(width: 12),
                      Text('Mengunduh invoice ${order.invoiceNumber}...'),
                    ],
                  ),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.download_rounded),
            label: const Text('Unduh Invoice'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showComplaintDialog(context);
            },
            icon: const Icon(Icons.report_problem_outlined),
            label: const Text('Ajukan Komplain'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showReorderDialog(context);
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Pesan Lagi'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
        if (order.status == OrderStatus.cancelled) ...[
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showReorderDialog(context);
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Pesan Lagi'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              Icons.warning_rounded,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 12),
            const Text('Batalkan Pesanan?'),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin membatalkan pesanan ini? Dana akan dikembalikan ke akun Anda.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tidak'),
          ),
          FilledButton(
            onPressed: () {
              // close dialog first
              Navigator.pop(context);
              // then close bottom sheet
              Navigator.pop(context);
              // finally perform cancellation callback
              onRequestCancel();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
  }

  void _showComplaintDialog(BuildContext context) {
    final complaintController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              Icons.report_problem_rounded,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 12),
            const Text('Ajukan Komplain'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jelaskan kendala atau keluhan Anda mengenai layanan ini:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: complaintController,
              decoration: InputDecoration(
                hintText: 'Tulis komplain Anda...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 12),
                      Text('Komplain berhasil dikirim'),
                    ],
                  ),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
  }

  void _showReorderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              Icons.refresh_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            const Text('Pesan Lagi'),
          ],
        ),
        content: Text(
          'Apakah Anda ingin memesan layanan yang sama dari ${order.providerName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Membuat pesanan baru...'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            child: const Text('Ya, Pesan'),
          ),
        ],
      ),
    );
  }
}

// Models
enum OrderStatus {
  pending,
  inProgress,
  completed,
  cancelled,
}

class OrderItem {
  final String id;
  final String invoiceNumber;
  final String providerName;
  final String category;
  final OrderStatus status;
  final DateTime date;
  final String time;
  final int totalAmount;
  final List<String> services;
  final String paymentMethod;
  final double progress;
  final int? rating;

  OrderItem({
    required this.id,
    required this.invoiceNumber,
    required this.providerName,
    required this.category,
    required this.status,
    required this.date,
    required this.time,
    required this.totalAmount,
    required this.services,
    required this.paymentMethod,
    this.progress = 0.0,
    this.rating,
  });
}
