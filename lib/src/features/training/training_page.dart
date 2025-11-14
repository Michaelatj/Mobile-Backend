import 'package:flutter/material.dart';
import '../../core/widgets/app_bottom_nav.dart';

class TrainingPage extends StatelessWidget {
  static const routePath = '/training';
  const TrainingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBottomNavScaffold(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(
            leading: Icon(Icons.play_circle_outline),
            title: Text('Modul: Dasar Keselamatan Kerja'),
            subtitle: Text('Video + Kuis • Badge otomatis'),
          ),
          ListTile(
            leading: Icon(Icons.play_circle_outline),
            title: Text('Modul: Pelayanan Pelanggan'),
            subtitle: Text('Video + Kuis • Sertifikat digital'),
          ),
        ],
      ),
    );
  }
}
