import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import 'core/theme.dart';
import 'core/state/providers.dart';
import 'core/state/auth_state.dart';

class LayananLokalApp extends ConsumerWidget {
  const LayananLokalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final lastRoute = ref.watch(lastRouteProvider);
    final lastApplied = ref.watch(lastRouteAppliedProvider);
    final auth = ref.watch(authStateProvider);

    // Apply last-route after first frame if user is authenticated and route valid
    if (!lastApplied && auth.isAuthenticated && isValidLastRoute(lastRoute)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // double-check still valid
        if (isValidLastRoute(lastRoute)) {
          router.go(lastRoute);
          ref.read(lastRouteAppliedProvider.notifier).state = true;
        }
      });
    }
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
