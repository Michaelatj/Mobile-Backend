import 'package:flutter/material.dart';
import 'package:flutter_application_1/src/features/profile/profile_page.dart';
import '../../core/services/firebase_analytics_service.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsPage extends StatefulWidget {
  static const routePath = '/profile/notifications';
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _isNotificationOn = true;

  final items = const [
    ('Pesanan', 'Pesanan #INV-003 telah selesai'),
    ('Promo', 'Diskon 20% untuk jasa kebersihan!'),
    ('Pesan', 'Penyedia membalas chat Anda'),
  ];

  @override
  void initState() {
    super.initState();
    _loadSwitchState();
    // Log analytics: notifications screen viewed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        FirebaseAnalyticsService.logNotificationsViewEvent(
          userId: 'unknown',
          notificationCount: items.length,
          notificationTypes: const ['pesanan', 'promo', 'pesan'],
        );
      } catch (_) {}
    });
  }

  Future<void> _loadSwitchState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isNotificationOn = prefs.getBool('notif_switch') ?? true;
    });
  }

  Future<void> _saveSwitchState(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_switch', value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
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
        actions: [
          Row(
            children: [
              const Text('Aktifkan Notifikasi'),
              Switch(
                value: _isNotificationOn,
                onChanged: (value) {
                  setState(() {
                    _isNotificationOn = value;
                  });
                  _saveSwitchState(value);
                },
              ),
            ],
          ),
        ],
      ),
      body: _isNotificationOn
          ? ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final (title, msg) = items[i];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.notifications_outlined),
                    title: Text(title),
                    subtitle: Text(msg),
                    trailing: TextButton(
                      onPressed: () {},
                      child: const Text('Tandai dibaca'),
                    ),
                  ),
                );
              },
            )
          : const Center(
              child: Text(
                'Notifikasi dimatikan',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
    );
  }
}
