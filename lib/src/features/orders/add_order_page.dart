import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/order.dart';
import '../../core/state/auth_state.dart';
import '../../core/state/order_provider.dart';
import '../../core/services/firebase_analytics_nonblocking.dart';

class AddOrderPage extends ConsumerWidget {
  static const routePath = '/orders/add';
  const AddOrderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tambah Pesanan')),
        body: const Center(child: Text('Silakan login terlebih dahulu')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Pesanan Baru'),
      ),
      body: AddOrderForm(
        userId: user.id,
        onOrderAdded: () {
          // Log analytics event
          FirebaseAnalyticsNonBlocking.logBookingCreatedEvent(
            userId: user.id,
            bookingId: 'temp_id', // Will be updated after order is created
            providerId: 'temp_provider',
            amount: 0,
          );
          
          // Navigate back to orders page
          Navigator.pop(context);
        },
      ),
    );
  }
}

class AddOrderForm extends ConsumerStatefulWidget {
  final String userId;
  final VoidCallback onOrderAdded;

  const AddOrderForm({
    Key? key,
    required this.userId,
    required this.onOrderAdded,
  }) : super(key: key);

  @override
  ConsumerState<AddOrderForm> createState() => _AddOrderFormState();
}

class _AddOrderFormState extends ConsumerState<AddOrderForm> {
  final _formKey = GlobalKey<FormState>();
  final _serviceNameController = TextEditingController();
  final _serviceProviderController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _notesController = TextEditingController();
  final _dateController = TextEditingController();

  OrderStatus _selectedStatus = OrderStatus.pending;
  DateTime? _selectedDate;

  @override
  void dispose() {
    _serviceNameController.dispose();
    _serviceProviderController.dispose();
    _totalAmountController.dispose();
    _notesController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Service Name
          TextFormField(
            controller: _serviceNameController,
            decoration: const InputDecoration(
              labelText: 'Nama Layanan',
              prefixIcon: Icon(Icons.build_rounded),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Nama layanan wajib diisi';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Service Provider
          TextFormField(
            controller: _serviceProviderController,
            decoration: const InputDecoration(
              labelText: 'Penyedia Layanan',
              prefixIcon: Icon(Icons.business_rounded),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Nama penyedia layanan wajib diisi';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Total Amount
          TextFormField(
            controller: _totalAmountController,
            decoration: const InputDecoration(
              labelText: 'Total Biaya',
              prefixIcon: Icon(Icons.attach_money_rounded),
              hintText: 'Rp 0',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Total biaya wajib diisi';
              }
              final amount = double.tryParse(value);
              if (amount == null || amount <= 0) {
                return 'Masukkan jumlah yang valid';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Scheduled Date
          TextFormField(
            controller: _dateController,
            decoration: const InputDecoration(
              labelText: 'Tanggal Jadwal',
              prefixIcon: Icon(Icons.calendar_today_rounded),
            ),
            readOnly: true,
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) {
                setState(() {
                  _selectedDate = date;
                  _dateController.text = DateFormat('dd/MM/yyyy').format(date);
                });
              }
            },
          ),
          const SizedBox(height: 16),

          // Notes
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Catatan',
              prefixIcon: Icon(Icons.note_rounded),
              hintText: 'Catatan tambahan untuk pesanan',
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),

          // Status Selection
          const Text('Status Pesanan', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: OrderStatus.values.map((status) {
              return ChoiceChip(
                label: Text(_getStatusDisplayText(status)),
                selected: _selectedStatus == status,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedStatus = status;
                    });
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          // Submit Button
          FilledButton.icon(
            onPressed: _submitOrder,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Tambahkan Pesanan'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusDisplayText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Menunggu';
      case OrderStatus.confirmed:
        return 'Dikonfirmasi';
      case OrderStatus.inProgress:
        return 'Berlangsung';
      case OrderStatus.completed:
        return 'Selesai';
      case OrderStatus.cancelled:
        return 'Dibatalkan';
    }
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final order = Order(
        id: '', // Will be generated by Firestore
        userId: widget.userId,
        serviceName: _serviceNameController.text,
        serviceProviderName: _serviceProviderController.text,
        totalAmount: double.parse(_totalAmountController.text),
        status: _selectedStatus,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        scheduledAt: _selectedDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        // serviceId and serviceProviderId are optional
      );

      // Add the order to Firestore
      await ref.read(addOrderProvider.notifier).addOrder(order);

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pesanan berhasil ditambahkan'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Call the callback
      widget.onOrderAdded();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambahkan pesanan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}