// lib/src/features/booking/payment_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/auth_state.dart';
import '../../core/models/booking.dart';
import '../../core/models/service_provider.dart';
import '../../core/database/booking_dao.dart';

class PaymentPage extends ConsumerStatefulWidget {
  static const routePath = '/booking/payment';

  final ServiceProvider provider;
  final DateTime selectedDate;
  final int durationHours;
  final String? note;
  final int totalAmount;

  const PaymentPage({
    super.key,
    required this.provider,
    required this.selectedDate,
    required this.durationHours,
    this.note,
    required this.totalAmount,
  });

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  String? _selectedPaymentMethod;
  bool _isProcessing = false;

  final List<PaymentMethodItem> _paymentMethods = [
    PaymentMethodItem(
      id: 'gopay',
      name: 'GoPay',
      icon: Icons.account_balance_wallet,
      color: Colors.green,
      category: 'E-Wallet',
    ),
    PaymentMethodItem(
      id: 'ovo',
      name: 'OVO',
      icon: Icons.account_balance_wallet,
      color: Colors.purple,
      category: 'E-Wallet',
    ),
    PaymentMethodItem(
      id: 'dana',
      name: 'DANA',
      icon: Icons.account_balance_wallet,
      color: Colors.blue,
      category: 'E-Wallet',
    ),
    PaymentMethodItem(
      id: 'shopeepay',
      name: 'ShopeePay',
      icon: Icons.account_balance_wallet,
      color: Colors.orange,
      category: 'E-Wallet',
    ),
    PaymentMethodItem(
      id: 'credit_card',
      name: 'Kartu Kredit/Debit',
      icon: Icons.credit_card,
      color: Colors.indigo,
      category: 'Kartu',
    ),
    PaymentMethodItem(
      id: 'bank_transfer',
      name: 'Transfer Bank',
      icon: Icons.account_balance,
      color: Colors.teal,
      category: 'Transfer',
    ),
  ];

  String _generateInvoiceCode() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = const Uuid().v4().substring(0, 6);
    return 'INV-${timestamp.toString().substring(0, 10)}-$random';
  }

  Future<void> _processPayment() async {
    if (_selectedPaymentMethod == null) {
      _showErrorSnackBar('Pilih metode pembayaran terlebih dahulu');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      final user = ref.read(authStateProvider).user;
      if (user == null) {
        _showErrorSnackBar('Anda harus login terlebih dahulu');
        return;
      }

      final invoiceCode = _generateInvoiceCode();

      // 1. SIMPAN BOOKING KE SQLITE — INI YANG BIKIN PESANAN MUNCUL!
      final booking = Booking(
        id: const Uuid().v4(),
        userId: user.id,
        providerId: widget.provider.id,
        status: BookingStatus.pending,
        createdAt: DateTime.now(),
        date: widget.selectedDate,
        durationHours: widget.durationHours,
        note: widget.note,
        estimatedCost: widget.totalAmount,
        paymentMethod: _selectedPaymentMethod,
      );

      await BookingDao.insertBooking(booking);

      // 2. Proses pembayaran backend (opsional)
      final orderData = {
        'amount': widget.totalAmount,
        'paymentMethod': _selectedPaymentMethod,
        'provider': widget.provider.name,
        'date': DateFormat('dd MMM yyyy').format(widget.selectedDate),
        'time': DateFormat('HH:mm').format(widget.selectedDate),
        'duration': widget.durationHours,
        'timestamp': DateTime.now().toIso8601String(),
        'bookingId': booking.id,
      };

      final success = await ref.read(authStateProvider.notifier).processPayment(
            invoiceCode: invoiceCode,
            orderData: orderData,
          );

      if (!mounted) return;

      if (success) {
        _showSuccessDialog(invoiceCode);
      } else {
        _showErrorSnackBar('Pembayaran gagal. Silakan coba lagi.');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Terjadi kesalahan: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
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

  void _showSuccessDialog(String invoiceCode) {
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
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Pembayaran Berhasil!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Pesanan Anda telah dikonfirmasi. Dana akan ditahan hingga layanan selesai.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Kode Invoice',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      invoiceCode,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                            fontFamily: 'monospace',
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  // LANGSUNG KE HALAMAN ORDERS
                  context.go('/orders');
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Lihat Pesanan Saya'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Pembayaran'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
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
                  ],
                ),
              ),
              _buildBottomActionBar(),
            ],
          ),
          if (_isProcessing) _buildProcessingOverlay(),
        ],
      ),
    );
  }

  Widget _buildEscrowBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.shield_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pembayaran Aman (Escrow)',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Dana Anda akan ditahan hingga layanan selesai dan dikonfirmasi',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer
                            .withOpacity(0.8),
                      ),
                ),
              ],
            ),
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
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Ringkasan Pesanan',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSummaryRow(
              icon: Icons.home_repair_service_rounded,
              label: 'Penyedia Jasa',
              value: widget.provider.name,
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              icon: Icons.calendar_today_rounded,
              label: 'Tanggal & Waktu',
              value:
                  '${DateFormat('dd MMM yyyy').format(widget.selectedDate)}, ${DateFormat('HH:mm').format(widget.selectedDate)}',
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              icon: Icons.access_time_rounded,
              label: 'Durasi',
              value: '${widget.durationHours} jam',
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Pembayaran',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'Rp ${NumberFormat('#,###', 'id_ID').format(widget.totalAmount)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
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
              child: Text(
                entry.key,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            ...entry.value.map((method) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildPaymentMethodCard(method),
                )),
          ],
        );
      }).toList(),
    );
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
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: method.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                method.icon,
                color: method.color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                method.name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  size: 20,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              )
            else
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    width: 2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Informasi Pembayaran',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoItem('• Pembayaran akan diproses melalui gateway yang aman'),
          const SizedBox(height: 6),
          _buildInfoItem('• Dana akan ditahan hingga layanan selesai'),
          const SizedBox(height: 6),
          _buildInfoItem('• Anda dapat mengajukan refund jika layanan tidak sesuai'),
          const SizedBox(height: 6),
          _buildInfoItem('• Dana akan diteruskan ke penyedia setelah konfirmasi selesai'),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Pembayaran',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rp ${NumberFormat('#,###', 'id_ID').format(widget.totalAmount)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                  ),
                  FilledButton.icon(
                    onPressed: _isProcessing ? null : _processPayment,
                    icon: const Icon(Icons.lock_rounded),
                    label: const Text('Bayar Sekarang'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 20),
                Text(
                  'Memproses Pembayaran...',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mohon tunggu sebentar',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PaymentMethodItem {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String category;

  PaymentMethodItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.category,
  });
}
