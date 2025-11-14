import 'package:flutter/material.dart';
import '../../core/widgets/app_bottom_nav.dart';

class PartnerDashboardPage extends StatelessWidget {
  static const routePath = '/partner/dashboard';
  const PartnerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBottomNavScaffold(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ListTile(
            leading: Icon(Icons.bar_chart),
            title: Text('Statistik Promosi'),
            subtitle: Text('Impresi, klik, pesanan'),
          ),
          const ListTile(
            leading: Icon(Icons.request_page_outlined),
            title: Text('Laporan Bulanan'),
            subtitle: Text('Unduh PDF'),
          ),
          FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.campaign_outlined), label: const Text('Tambah Iklan Baru')),
        ],
      ),
    );
  }
}
