import 'package:flutter/material.dart';
import '../../core/widgets/app_bottom_nav.dart';

class CommunityPage extends StatelessWidget {
  static const routePath = '/community';
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBottomNavScaffold(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (_, i) {
          return Card(
            child: ListTile(
              title: Text('Postingan #$i'),
              subtitle: const Text('Isi konten, komentar, like...'),
              trailing: IconButton(
                icon: const Icon(Icons.flag_outlined),
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dilaporkan'))),
              ),
            ),
          );
        },
      ),
    );
  }
}
