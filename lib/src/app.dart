import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import 'core/theme.dart';
// state providers are used inside the router provider; no direct imports needed here

class LayananLokalApp extends ConsumerWidget {
  const LayananLokalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    // Navigation initial location is handled by the router provider
    // (it computes a safe initialLocation based on auth and lastRoute).
    // Avoid calling router.go() during build/post-frame which can trigger
    // Navigator state update conflicts when the framework is mid-build.
    return MaterialApp.router(
      title: 'Layanan Lokal',
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
