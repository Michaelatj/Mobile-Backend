import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/auth/onboarding_page.dart';
import 'features/auth/login_page.dart';
import 'features/auth/register_page.dart';
import 'features/auth/role_selection_page.dart';
import 'features/auth/provider_onboarding_page.dart';
import 'features/profile/profile_setup_page.dart';
import 'features/home/home_page.dart';
import 'features/providers/provider_detail_page.dart';
import 'features/booking/booking_form_page.dart';
import 'features/booking/payment_page.dart';
import 'features/orders/orders_page.dart';
import 'features/profile/profile_page.dart';
import 'features/profile/edit_profile_page.dart';
import 'features/training/training_page.dart';
import 'features/community/community_page.dart';
import 'features/notifications/notifications_page.dart';
import 'features/help/help_page.dart';
import 'features/partner/partner_dashboard_page.dart';
import 'core/models/service_provider.dart';
import 'core/state/auth_state.dart';
import 'core/state/providers.dart';

// Root navigator key
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

// === Validasi Last Route ===
const Set<String> _validLastRoutes = {
  HomePage.routePath,
  ProfilePage.routePath,
  TrainingPage.routePath,
  CommunityPage.routePath,
  OrdersPage.routePath,
  PartnerDashboardPage.routePath,
  '${ProfilePage.routePath}/edit',
  '${ProfilePage.routePath}/notifications',
  '${ProfilePage.routePath}/help',
};

bool isValidLastRoute(String? route) {
  if (route == null || route.isEmpty) return false;
  return _validLastRoutes.contains(route);
}

// === GoRouter Provider ===
final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authStateProvider);
  final lastRoute = ref.watch(lastRouteProvider);

  final initialLocation = auth.isAuthenticated
      ? (isValidLastRoute(lastRoute) ? lastRoute : HomePage.routePath)
      : OnboardingPage.routePath;

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: initialLocation,
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(auth),
    redirect: (context, state) {
  final isAuthFlow = {
    OnboardingPage.routePath,
    LoginPage.routePath,
    RegisterPage.routePath,
    RoleSelectionPage.routePath,
    ProviderOnboardingPage.routePath,
    ProfileSetupPage.routePath,
  }.contains(state.uri.toString()); // GUNAKAN state.uri.toString()

  if (!auth.isAuthenticated && !isAuthFlow) {
    return OnboardingPage.routePath;
  }

  if (auth.isAuthenticated && isAuthFlow) {
    return isValidLastRoute(lastRoute) ? lastRoute : HomePage.routePath;
  }

  return null;
},
    observers: [_LastRouteObserver()],
    routes: [
      // === Auth Flow ===
      GoRoute(path: OnboardingPage.routePath, builder: (_, __) => const OnboardingPage()),
      GoRoute(path: LoginPage.routePath, builder: (_, __) => const LoginPage()),
      GoRoute(path: RegisterPage.routePath, builder: (_, __) => const RegisterPage()),
      GoRoute(path: RoleSelectionPage.routePath, builder: (_, __) => const RoleSelectionPage()),
      GoRoute(path: ProviderOnboardingPage.routePath, builder: (_, __) => const ProviderOnboardingPage()),
      GoRoute(path: ProfileSetupPage.routePath, builder: (_, __) => const ProfileSetupPage()),

      // === Main App ===
      GoRoute(path: HomePage.routePath, builder: (_, __) => const HomePage()),

      // === Provider Detail + Nested (HANYA 1 ROUTE) ===
      GoRoute(
        path: ProviderDetailPage.routePath, // /provider/detail/:id
        builder: (_, state) => ProviderDetailPage(
          providerId: state.pathParameters['id']!,
        ),
        routes: [
          GoRoute(
            path: 'book',
            builder: (_, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return BookingFormPage(
                providerId: extra?['providerId'] as String? ?? state.pathParameters['id'],
                providerName: extra?['providerName'] as String?,
                priceFrom: extra?['priceFrom'] as int?,
              );
            },
          ),
        ],
      ),

      // === Payment Page ===
      GoRoute(
        path: PaymentPage.routePath,
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;

          if (extra?['provider'] == null ||
              extra?['selectedDate'] == null ||
              extra?['durationHours'] == null ||
              extra?['totalAmount'] == null) {
            return const Scaffold(
              body: Center(
                child: Text(
                  'Error: Data pembayaran tidak lengkap.\nSilakan ulangi pemesanan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            );
          }

          return PaymentPage(
            provider: extra!['provider'] as ServiceProvider,
            selectedDate: extra['selectedDate'] as DateTime,
            durationHours: extra['durationHours'] as int,
            totalAmount: extra['totalAmount'] as int,
          );
        },
      ),

      // === Orders ===
      GoRoute(path: OrdersPage.routePath, builder: (_, __) => const OrdersPage()),

      // === Profile + Nested ===
      GoRoute(
        path: ProfilePage.routePath,
        builder: (_, __) => const ProfilePage(),
        routes: [
          GoRoute(path: 'edit', builder: (_, __) => const EditProfilePage()),
          GoRoute(path: 'notifications', builder: (_, __) => const NotificationsPage()),
          GoRoute(path: 'help', builder: (_, __) => const HelpPage()),
        ],
      ),

      // === Other Pages ===
      GoRoute(path: TrainingPage.routePath, builder: (_, __) => const TrainingPage()),
      GoRoute(path: CommunityPage.routePath, builder: (_, __) => const CommunityPage()),
      GoRoute(path: HelpPage.routePath, builder: (_, __) => const HelpPage()),
      GoRoute(path: PartnerDashboardPage.routePath, builder: (_, __) => const PartnerDashboardPage()),
    ],
  );
});

// === Refresh Stream ===
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(AuthState auth) {
    _subscription = Stream.value(auth).listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// === Last Route Observer (FIXED: location dari GoRouterState) ===
class _LastRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _saveRoute();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _saveRoute();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _saveRoute();
  }

  Future<void> _saveRoute() async {
    final context = _rootNavigatorKey.currentContext;
    if (context == null) return;

    String? location;
    try {
      // PAKAI GoRouterState → .location
      final state = GoRouterState.of(context);
      location = state.uri.toString();
    } catch (e) {
      debugPrint('Error getting location: $e');
      return;
    }

    if (location.isEmpty) return;

    // Normalisasi
    final normalized = location.startsWith('/') ? location : '/$location';

    // Validasi
    if (!_validLastRoutes.contains(normalized)) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_route', normalized);
      debugPrint('Last route saved: $normalized');
    } catch (e) {
      debugPrint('Error saving last route: $e');
    }
  }
}