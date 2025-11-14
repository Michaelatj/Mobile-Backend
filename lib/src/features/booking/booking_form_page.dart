import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/database/provider_dao.dart';
import '../../core/models/service_provider.dart';
import '../../core/state/auth_state.dart';
import '../../core/services/firebase_analytics_service.dart';
import 'payment_page.dart';

class BookingFormPage extends ConsumerStatefulWidget {
  static const routePath = '/booking/form';

  final String? providerId;
  final String? providerName;
  final int? priceFrom;

  const BookingFormPage({
    super.key,
    this.providerId,
    this.providerName,
    this.priceFrom,
  });

  @override
  ConsumerState<BookingFormPage> createState() => _BookingFormPageState();
}

class _BookingFormPageState extends ConsumerState<BookingFormPage> {
  late String providerId;
  late String providerName;
  late int basePricePerHour; // ← Dari provider, bukan hardcode

  DateTime? _date;
  TimeOfDay? _time;
  int _duration = 1;
  String _serviceType = 'Reguler';
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();
  bool _needTools = false;
  bool _isExpress = false;

  // Biaya tetap
  static const int _toolsPrice = 50000;
  static const double _platformFeePercent = 0.05;
  static const double _expressMultiplier = 1.2; // +20%
  static const int _expressFlatFee = 50000; // Tambahan flat untuk express

  // === PERHITUNGAN HARGA ===
  int get subtotal => basePricePerHour * _duration;

  int get expressFee {
    if (!_isExpress) return 0;
    final percentage = (subtotal * (_expressMultiplier - 1)).round();
    return percentage + _expressFlatFee;
  }

  int get toolsCost => _needTools ? _toolsPrice : 0;

  int get platformFee {
    final base = subtotal + expressFee;
    return (base * _platformFeePercent).round();
  }

  int get total {
    return subtotal + expressFee + toolsCost + platformFee;
  }

  @override
  void initState() {
    super.initState();
    providerId = widget.providerId ?? '';
    providerName = widget.providerName ?? 'Penyedia Layanan';
    basePricePerHour = widget.priceFrom ?? 150000; // Default jika tidak ada
  }

  @override
  void dispose() {
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
      initialDate: _date ?? now,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _proceedToPayment() async {
    if (providerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Provider tidak ditemukan')),
      );
      return;
    }

    final selDate = _date ?? DateTime.now();
    final selTime = _time ?? TimeOfDay.now();
    final scheduled = DateTime(
      selDate.year,
      selDate.month,
      selDate.day,
      selTime.hour,
      selTime.minute,
    );

    final provider = await ProviderDao.getProviderById(providerId);
    if (provider == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data penyedia tidak ditemukan')),
      );
      return;
    }

    try {
      final userId = ref.read(authStateProvider).user?.id ?? 'unknown';
      await FirebaseAnalyticsService.logBookingSubmitEvent(
        userId: userId,
        providerId: providerId,
        serviceType: _serviceType,
        totalAmount: total,
        durationHours: _duration,
      );
    } catch (_) {}

    context.go(
      PaymentPage.routePath,
      extra: {
        'provider': provider,
        'selectedDate': scheduled,
        'durationHours': _duration,
        'totalAmount': total,
        'note': _noteController.text,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Form Pemesanan'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildProviderInfoCard(),
                const SizedBox(height: 20),
                _buildSectionTitle('Jenis Layanan'),
                const SizedBox(height: 12),
                _buildServiceTypeSelector(),
                const SizedBox(height: 24),
                _buildSectionTitle('Jadwal Layanan'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildDateSelector()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTimeSelector()),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Durasi Layanan'),
                const SizedBox(height: 12),
                _buildDurationSelector(),
                const SizedBox(height: 24),
                _buildSectionTitle('Alamat Layanan'),
                const SizedBox(height: 12),
                _buildAddressInput(),
                const SizedBox(height: 24),
                _buildSectionTitle('Opsi Tambahan'),
                const SizedBox(height: 12),
                _buildToolsOption(),
                const SizedBox(height: 24),
                _buildSectionTitle('Catatan (Opsional)'),
                const SizedBox(height: 12),
                _buildNotesInput(),
                const SizedBox(height: 24),
                _buildPriceSummary(),
                const SizedBox(height: 100),
              ],
            ),
          ),
          _buildBottomActionBar(),
        ],
      ),
    );
  }

  Widget _buildProviderInfoCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primaryContainer,
                    Theme.of(context).colorScheme.secondaryContainer,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.home_repair_service_rounded,
                size: 28,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    providerName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star_rounded, size: 16, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 4),
                      Text('4.8', style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Terverifikasi',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildServiceTypeSelector() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildServiceTypeChip('Reguler', 'Jadwal normal', Icons.schedule),
        _buildServiceTypeChip('Express', 'Cepat (+20% + Rp 50.000)', Icons.bolt),
      ],
    );
  }

  Widget _buildServiceTypeChip(String type, String subtitle, IconData icon) {
    final isSelected = _serviceType == type;
    return InkWell(
      onTap: () {
        setState(() {
          _serviceType = type;
          _isExpress = type == 'Express';
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Theme.of(context).colorScheme.onPrimaryContainer : null,
                      ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8)
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.check_circle, size: 20, color: Colors.green),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _date != null
              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _date != null ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: _date != null ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text('Tanggal', style: Theme.of(context).textTheme.labelMedium),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _date == null ? 'Pilih tanggal' : DateFormat('dd MMM yyyy', 'id_ID').format(_date!),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _date != null ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector() {
    return InkWell(
      onTap: _selectTime,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _time != null
              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _time != null ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 18,
                  color: _time != null ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text('Waktu', style: Theme.of(context).textTheme.labelMedium),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _time == null ? 'Pilih waktu' : _time!.format(context),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _time != null ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_duration Jam',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              Text(
                'Rp ${NumberFormat('#,###', 'id_ID').format(subtotal)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildDurationButton(
                icon: Icons.remove,
                onPressed: _duration > 1 ? () => setState(() => _duration--) : null,
              ),
              Expanded(
                child: Slider(
                  value: _duration.toDouble(),
                  min: 1,
                  max: 8,
                  divisions: 7,
                  label: '$_duration jam',
                  onChanged: (value) => setState(() => _duration = value.round()),
                ),
              ),
              _buildDurationButton(
                icon: Icons.add,
                onPressed: _duration < 8 ? () => setState(() => _duration++) : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Rp ${NumberFormat('#,###', 'id_ID').format(basePricePerHour)} per jam',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationButton({required IconData icon, required VoidCallback? onPressed}) {
    return Container(
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(8)),
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
        iconSize: 20,
      ),
    );
  }

  Widget _buildAddressInput() {
    return TextField(
      controller: _addressController,
      decoration: InputDecoration(
        hintText: 'Masukkan alamat lengkap',
        prefixIcon: const Icon(Icons.location_on_rounded),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)),
      ),
      maxLines: 2,
    );
  }

  Widget _buildToolsOption() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _needTools ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outlineVariant, width: _needTools ? 2 : 1),
      ),
      child: CheckboxListTile(
        value: _needTools,
        onChanged: (value) => setState(() => _needTools = value ?? false),
        title: Row(
          children: [
            Icon(Icons.build_circle_rounded, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Butuh Peralatan'),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(left: 32),
          child: Text('Tambahan Rp ${NumberFormat('#,###', 'id_ID').format(_toolsPrice)}', style: Theme.of(context).textTheme.bodySmall),
        ),
        controlAffinity: ListTileControlAffinity.trailing,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildNotesInput() {
    return TextField(
      controller: _noteController,
      decoration: InputDecoration(
        hintText: 'Tambahkan catatan khusus...',
        prefixIcon: const Icon(Icons.note_alt_outlined),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)),
      ),
      maxLines: 3,
    );
  }

  Widget _buildPriceSummary() {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long_rounded, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('Rincian Biaya', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            _buildPriceRow('Biaya layanan ($_duration jam)', subtotal),
            if (_isExpress) ...[
              const SizedBox(height: 8),
              _buildPriceRow('Express (+20% + Rp 50.000)', expressFee),
            ],
            if (_needTools) ...[
              const SizedBox(height: 8),
              _buildPriceRow('Peralatan', toolsCost),
            ],
            const SizedBox(height: 8),
            _buildPriceRow('Biaya platform (5%)', platformFee),
            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Pembayaran', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                Text(
                  'Rp ${NumberFormat('#,###', 'id_ID').format(total)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, int amount) {
    if (amount == 0) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        Text('Rp ${NumberFormat('#,###', 'id_ID').format(amount)}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, -4))],
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Pembayaran', style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${NumberFormat('#,###', 'id_ID').format(total)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: _proceedToPayment,
                icon: const Icon(Icons.payment_rounded),
                label: const Text('Lanjut Bayar'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}