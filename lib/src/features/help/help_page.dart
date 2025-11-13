import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  static const routePath = '/help';
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bantuan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ExpansionTile(
            title: Text('FAQ'),
            children: [ListTile(title: Text('Bagaimana cara memesan jasa?')), ListTile(title: Text('Metode pembayaran?'))],
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat CS coming soon'))),
            child: const Text('Chat CS'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Keluhan terkirim'))),
            child: const Text('Kirim Keluhan'),
          ),
        ],
      ),
    );
  }
}
