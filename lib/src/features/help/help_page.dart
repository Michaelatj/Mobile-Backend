import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/firebase_analytics_service.dart';

class HelpPage extends StatelessWidget {
  static const routePath = '/help';
  const HelpPage({super.key});

  void _handleBack(BuildContext context) {
    // Use GoRouter to navigate back; if no history, go to profile
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      context.go('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bantuan'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => _handleBack(context),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const ExpansionTile(
              title: Text('FAQ'),
              children: [
                ListTile(title: Text('Bagaimana cara memesan jasa?')),
                ListTile(title: Text('Metode pembayaran?'))
              ],
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () {
                FirebaseAnalyticsService.logApiCallEvent(
                  endpoint: 'help_chat_cs',
                  method: 'POST',
                  statusCode: 200,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chat CS coming soon')));
              },
              child: const Text('Chat CS'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                FirebaseAnalyticsService.logApiCallEvent(
                  endpoint: 'help_submit_complaint',
                  method: 'POST',
                  statusCode: 200,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Keluhan terkirim')));
              },
              child: const Text('Kirim Keluhan'),
            ),
          ],
        ),
      ),
    );
  }
}
