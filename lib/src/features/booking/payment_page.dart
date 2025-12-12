import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/state/providers.dart';
import '../../core/database/booking_dao.dart';
import '../../core/state/auth_state.dart';
import '../../core/models/booking.dart';
import '../../features/orders/orders_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import '../../core/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/firebase_analytics_service.dart';

class PaymentPage extends ConsumerStatefulWidget {
  static const routePath = '/booking/payment';
  const PaymentPage({super.key});

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  String? _selectedPaymentMethod;
  bool _isProcessing = false;

  // fallback/mock values (used if extras missing)
  int _totalAmountLocal = 0;
  String _providerNameLocal = 'Penyedia Jasa';
  DateTime _scheduledLocal = DateTime.now();
  int _durationLocal = 1;
  bool _isExpressLocal = false;
  bool _needToolsLocal = false;
  String? _providerIdLocal;
  String? _noteLocal;

  Map<String, dynamic>? bookingExtra;

  final List<PaymentMethodItem> _paymentMethods = [
    PaymentMethodItem(
        id: 'gopay',
        name: 'GoPay',
        icon: Icons.account_balance_wallet,
        color: Colors.green,
        category: 'E-Wallet'),
    PaymentMethodItem(
        id: 'ovo',
        name: 'OVO',
        icon: Icons.account_balance_wallet,
        color: Colors.purple,
        category: 'E-Wallet'),
    PaymentMethodItem(
        id: 'dana',
        name: 'DANA',
        icon: Icons.account_balance_wallet,
        color: Colors.blue,
        category: 'E-Wallet'),
    PaymentMethodItem(
        id: 'shopeepay',
        name: 'ShopeePay',
        icon: Icons.account_balance_wallet,
        color: Colors.orange,
        category: 'E-Wallet'),
    PaymentMethodItem(
        id: 'credit_card',
        name: 'Kartu Kredit/Debit',
        icon: Icons.credit_card,
        color: Colors.indigo,
        category: 'Kartu'),
    PaymentMethodItem(
        id: 'bank_transfer',
        name: 'Transfer Bank',
        icon: Icons.account_balance,
        color: Colors.teal,
        category: 'Transfer'),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extra = GoRouter.of(context).state.extra as Map<String, dynamic>?;
    bookingExtra = extra;

    if (bookingExtra != null) {
      _providerNameLocal =
          bookingExtra!['providerName'] as String? ?? _providerNameLocal;
      _scheduledLocal =
          DateTime.tryParse(bookingExtra!['scheduled'] as String? ?? '') ??
              _scheduledLocal;
      _durationLocal = (bookingExtra!['duration'] as int?) ?? _durationLocal;
      _totalAmountLocal =
          (bookingExtra!['totalAmount'] as int?) ?? _totalAmountLocal;
      _isExpressLocal = (bookingExtra!['isExpress'] as bool?) ?? false;
      _needToolsLocal = (bookingExtra!['needTools'] as bool?) ?? false;
      _providerIdLocal = bookingExtra!['providerId'] as String?;
      _noteLocal = bookingExtra!['note'] as String?;
    }
  }

  Future<void> _processPayment() async {
    // 1. Validasi
    if (_selectedPaymentMethod == null) {
      _showErrorSnackBar('Pilih metode pembayaran terlebih dahulu');
      return;
    }

    setState(() => _isProcessing = true);
    
    await Future.delayed(const Duration(seconds: 2)); 

    if (!mounted) return;

    // 👇 PERBAIKAN DI SINI:
    // Gunakan 'firebaseUser' (dari FirebaseAuth) bukan 'user' (dari Riverpod)
    // supaya kita bisa akses .email dan .displayName
    final firebaseUser = FirebaseAuth.instance.currentUser;
    
    // Cek kelengkapan data
    if (firebaseUser == null || _providerIdLocal == null) {
      setState(() => _isProcessing = false);
      _showErrorSnackBar('Data pemesanan tidak lengkap (User belum login)');
      return;
    }

    // 2. SIAPKAN FORMAT DATA 📝
    final newOrderData = {
      'userId': firebaseUser.uid, // Pakai .uid kalau dari Firebase
      'userName': firebaseUser.displayName ?? 'Tanpa Nama', // Sekarang aman ✅
      'userEmail': firebaseUser.email ?? 'Tanpa Email',     // Sekarang aman ✅
      'providerId': _providerIdLocal,
      'providerName': _providerNameLocal ?? 'Provider Jasa',
      'category': 'Umum', 
      'status': 'pending', 
      'date': Timestamp.fromDate(_scheduledLocal),
      'totalAmount': _totalAmountLocal,
      'services': ['Layanan Jasa'],
      'invoiceNumber': 'INV-${DateTime.now().millisecondsSinceEpoch}',
      'paymentMethod': _selectedPaymentMethod,
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      // 3. KIRIM KE FIRESTORE (Akan membuat collection 'orders' otomatis) 🚀
      print("Mengirim order ke Firestore...");
      await FirestoreService.createOrder(newOrderData);
      
      // 4. KIRIM KE ANALYTICS (Supaya DebugView Gerak!) 📊
      await FirebaseAnalyticsService.logBookingSubmitEvent(
        userId: firebaseUser.uid,
        providerId: _providerIdLocal!,
        serviceType: 'Umum',
        totalAmount: _totalAmountLocal,
        durationHours: _durationLocal,
      );

      print("Sukses! Data terkirim ke Firestore & Analytics.");

      if (mounted) {
        setState(() => _isProcessing = false);
        _showSuccessDialog();
      }
    } catch (e) {
      print("Error: $e");
      if (mounted) {
        setState(() => _isProcessing = false);
        _showErrorSnackBar('Gagal: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle_rounded,
                    size: 64, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 20),
              Text('Pembayaran Berhasil!',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                  'Pesanan Anda telah dikonfirmasi. Dana akan ditahan hingga layanan selesai.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  if (!mounted) return;
                  // go to OrdersPage (replace stack)
                  context.go(OrdersPage.routePath);
                },
                style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text('Lihat Pesanan Saya'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEscrowBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          Theme.of(context).colorScheme.primaryContainer,
          Theme.of(context).colorScheme.secondaryContainer
        ]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.shield_rounded,
                  color: Theme.of(context).colorScheme.primary, size: 32)),
          const SizedBox(width: 16),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Pembayaran Aman (Escrow)',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer)),
              const SizedBox(height: 4),
              Text(
                  'Dana Anda akan ditahan hingga layanan selesai dan dikonfirmasi',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimaryContainer
                          .withOpacity(0.8))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.receipt_long_rounded,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text('Ringkasan Pesanan',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold))
          ]),
          const SizedBox(height: 16),
          _buildSummaryRow(
              icon: Icons.home_repair_service_rounded,
              label: 'Penyedia Jasa',
              value: _providerNameLocal),
          const SizedBox(height: 12),
          _buildSummaryRow(
              icon: Icons.calendar_today_rounded,
              label: 'Tanggal & Waktu',
              value: DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
                  .format(_scheduledLocal)),
          const SizedBox(height: 12),
          _buildSummaryRow(
              icon: Icons.access_time_rounded,
              label: 'Durasi',
              value: '$_durationLocal jam'),
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1)),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Total Pembayaran',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Text(
                'Rp ${NumberFormat('#,###', 'id_ID').format(_totalAmountLocal)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary)),
          ]),
        ]),
      ),
    );
  }

  Widget _buildSummaryRow(
      {required IconData icon, required String label, required String value}) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon,
          size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
      const SizedBox(width: 12),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600))
      ])),
    ]);
  }

  Widget _buildPaymentMethods() {
    final Map<String, List<PaymentMethodItem>> groupedMethods = {};
    for (final method in _paymentMethods) {
      groupedMethods.putIfAbsent(method.category, () => []).add(method);
    }

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: groupedMethods.entries.map((entry) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (entry.key != groupedMethods.keys.first)
                  const SizedBox(height: 16),
                Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(entry.key,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant))),
                ...entry.value.map((method) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildPaymentMethodCard(method))),
              ]);
        }).toList());
  }

  Widget _buildPaymentMethodCard(PaymentMethodItem method) {
    final isSelected = _selectedPaymentMethod == method.id;
    return InkWell(
      onTap: () => setState(() => _selectedPaymentMethod = method.id),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outlineVariant,
              width: isSelected ? 2 : 1),
        ),
        child: Row(children: [
          Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: method.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(method.icon, color: method.color, size: 24)),
          const SizedBox(width: 16),
          Expanded(
              child: Text(method.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600))),
          isSelected
              ? Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle),
                  child: Icon(Icons.check,
                      size: 20, color: Theme.of(context).colorScheme.onPrimary))
              : Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                          width: 2))),
        ]),
      ),
    );
  }

  Widget _buildPaymentInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.info_outline_rounded,
              size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text('Informasi Pembayaran',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold))
        ]),
        const SizedBox(height: 12),
        _buildInfoItem('• Pembayaran akan diproses melalui gateway yang aman'),
        const SizedBox(height: 6),
        _buildInfoItem('• Dana akan ditahan hingga layanan selesai'),
        const SizedBox(height: 6),
        _buildInfoItem(
            '• Anda dapat mengajukan refund jika layanan tidak sesuai'),
        const SizedBox(height: 6),
        _buildInfoItem(
            '• Dana akan diteruskan ke penyedia setelah konfirmasi selesai'),
      ]),
    );
  }

  Widget _buildInfoItem(String text) => Text(text,
      style: Theme.of(context)
          .textTheme
          .bodySmall
          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant));

  Widget _buildBottomActionBar() {
    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, -4))
          ],
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24), topRight: Radius.circular(24))),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Total Pembayaran',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text(
                    'Rp ${NumberFormat('#,###', 'id_ID').format(_totalAmountLocal)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary)),
              ]),
              FilledButton.icon(
                  onPressed: _isProcessing ? null : _processPayment,
                  icon: const Icon(Icons.lock_rounded),
                  label: const Text('Bayar Sekarang'),
                  style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)))),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
        color: Colors.black54,
        child: Center(
            child: Card(
                margin: const EdgeInsets.all(32),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: 20),
                      Text('Memproses Pembayaran...',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Mohon tunggu sebentar',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant))
                    ])))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        appBar: AppBar(
            title: const Text('Pembayaran'), centerTitle: true, elevation: 0),
        body: Stack(children: [
          Column(children: [
            Expanded(
              child: ListView(padding: const EdgeInsets.all(16), children: [
                _buildEscrowBanner(),
                const SizedBox(height: 20),
                _buildOrderSummary(),
                const SizedBox(height: 24),
                _buildSectionTitle('Pilih Metode Pembayaran'),
                const SizedBox(height: 12),
                _buildPaymentMethods(),
                const SizedBox(height: 24),
                _buildPaymentInfo(),
                const SizedBox(height: 100),
              ]),
            ),
            _buildBottomActionBar(),
          ]),
          if (_isProcessing) _buildProcessingOverlay(),
        ]));
  }

  Widget _buildSectionTitle(String title) => Text(title,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.bold));
}

class PaymentMethodItem {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String category;

  PaymentMethodItem(
      {required this.id,
      required this.name,
      required this.icon,
      required this.color,
      required this.category});
}
