import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import 'core/theme.dart';

class LayananLokalApp extends ConsumerWidget {
  const LayananLokalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Layanan Lokal',
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      // Opsional: Tambahkan builder untuk error handling atau loading
      builder: (context, child) {
        // Bisa tambahkan global overlay, error boundary, dll.
        return child!;
      },
    );
  }
}