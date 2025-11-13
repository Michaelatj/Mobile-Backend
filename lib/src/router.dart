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
import 'features/reviews/review_section.dart';
import 'features/profile/profile_page.dart';
import 'features/profile/edit_profile_page.dart';
import 'features/training/training_page.dart';
import 'features/community/community_page.dart';
import 'features/notifications/notifications_page.dart';
import 'features/help/help_page.dart';
import 'features/partner/partner_dashboard_page.dart';
import 'core/state/auth_state.dart';
import 'core/state/providers.dart';

// A root navigator key so observers can read the current GoRouter location
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  // capture auth state once so redirect uses a stable value (no ref.read inside redirect)
  final auth = ref.watch(authStateProvider);
  final lastRoute = ref.watch(lastRouteProvider);

  // compute a safe start location: prefer a validated lastRoute for logged-in users
  final startLocation = (!auth.isAuthenticated)
      ? OnboardingPage.routePath
      : (isValidLastRoute(lastRoute) ? lastRoute : HomePage.routePath);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    // use computed, validated start location to avoid invalid-match asserts
    initialLocation: startLocation,
    debugLogDiagnostics: false,
    // use a single-value stream built from captured auth (provider will rebuild router when auth changes)
    refreshListenable: GoRouterRefreshStream(Stream.value(auth)),
    redirect: (context, state) {
      // use captured `auth` (no ref.read/watch here)
      final inAuthFlow = state.matchedLocation == LoginPage.routePath ||
          state.matchedLocation == RegisterPage.routePath ||
          state.matchedLocation == ProviderOnboardingPage.routePath;

      if (!auth.isAuthenticated &&
          !inAuthFlow &&
          state.matchedLocation != OnboardingPage.routePath) {
        return OnboardingPage.routePath;
      }
      // No special-case redirect to raw `lastRoute` here to avoid returning
      // a previously-saved but possibly invalid path. Initial navigation
      // is handled by `initialLocation` above.
      return null;
    },
    observers: [
      _LastRouteObserver(),
    ],
    routes: [
      GoRoute(
          path: OnboardingPage.routePath,
          builder: (_, __) => const OnboardingPage()),
      GoRoute(path: LoginPage.routePath, builder: (_, __) => const LoginPage()),
      GoRoute(
          path: RegisterPage.routePath,
          builder: (_, __) => const RegisterPage()),
      GoRoute(
          path: RoleSelectionPage.routePath,
          builder: (_, __) => const RoleSelectionPage()),
      GoRoute(
          path: ProviderOnboardingPage.routePath,
          builder: (_, __) => const ProviderOnboardingPage()),
      GoRoute(
          path: ProfileSetupPage.routePath,
          builder: (_, __) => const ProfileSetupPage()),

      // Home (top-level)
      GoRoute(path: HomePage.routePath, builder: (_, __) => const HomePage()),

      // Provider detail with nested review and booking children
      GoRoute(
        path: ProviderDetailPage.routePath, // '/provider/detail/:id'
        builder: (_, state) =>
            ProviderDetailPage(providerId: state.pathParameters['id']!),
        routes: [
          // /provider/detail/:id/reviews/:userId
          GoRoute(
            path: 'reviews/:userId',
            builder: (_, state) => ReviewSection(
              providerId: state.pathParameters['id']!,
              userId: state.pathParameters['userId']!,
            ),
          ),
          // /provider/detail/:id/book  (optional nested booking form)
          GoRoute(
            path: 'book',
            builder: (_, state) => BookingFormPage(
              providerId: state.pathParameters['id']!,
              providerName: (state.extra
                  as Map<String, dynamic>?)?['providerName'] as String?,
              priceFrom:
                  (state.extra as Map<String, dynamic>?)?['priceFrom'] as int?,
            ),
          ),
        ],
      ),

      // Booking / Payment / Orders
      GoRoute(
          path: BookingFormPage.routePath,
          builder: (_, __) => const BookingFormPage()),
      GoRoute(
          path: PaymentPage.routePath, builder: (_, __) => const PaymentPage()),
      GoRoute(
          path: OrdersPage.routePath, builder: (_, __) => const OrdersPage()),

      // Profile with nested children
      GoRoute(
        path: ProfilePage.routePath, // '/profile'
        builder: (_, __) => const ProfilePage(),
        routes: [
          GoRoute(
              path: 'edit',
              builder: (_, __) => const EditProfilePage()), // '/profile/edit'
          GoRoute(
              path: 'notifications',
              builder: (_, __) =>
                  const NotificationsPage()), // '/profile/notifications'
          GoRoute(
              path: 'help',
              builder: (_, __) => const HelpPage()), // '/profile/help'
        ],
      ),

      // Other top-level routes (removed /notifications as it's nested in /profile)
      GoRoute(
          path: TrainingPage.routePath,
          builder: (_, __) => const TrainingPage()),
      GoRoute(
          path: CommunityPage.routePath,
          builder: (_, __) => const CommunityPage()),
      GoRoute(path: HelpPage.routePath, builder: (_, __) => const HelpPage()),
      GoRoute(
          path: PartnerDashboardPage.routePath,
          builder: (_, __) => const PartnerDashboardPage()),
      // (No standalone /notifications route - notifications are nested under /profile)
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _subscription;
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Observer untuk menyimpan route terakhir yang dikunjungi ke SharedPreferences
/// Hanya menyimpan routes yang valid (bukan auth/onboarding/nested auth)
class _LastRouteObserver extends RouteObserver<PageRoute> {
  _LastRouteObserver();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _saveRoute(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _saveRoute(newRoute);
    }
  }

  void _saveRoute(Route<dynamic> route) {
    // Prefer RouteSettings.name but fall back to GoRouter.location (actual path)
    // because GoRouter-created routes often don't set settings.name.
    String? routeName = route.settings.name;

    String location = routeName ?? '';

    if (location.isEmpty) {
      // Try to obtain the current GoRouter location via the root navigator key
      final ctx = _rootNavigatorKey.currentContext;
      if (ctx != null) {
        try {
          // Use `dynamic` to avoid analyzer/version issues and read the current
          // GoRouter location at runtime.
          final dyn = GoRouter.of(ctx) as dynamic;
          final locVal = dyn.location as String?;
          if (locVal != null && locVal.isNotEmpty) {
            location = locVal;
          }
        } catch (_) {
          // ignore - we'll bail out below if still empty
        }
      }
    }

    if (location.isEmpty) return;

    // Skip routes that shouldn't be saved (auth, onboarding, etc.)
    if (_shouldSkipRoute(location)) return;

    _persistLastRoute(location);
  }

  /// Check apakah route harus di-skip dari last_route tracking
  bool _shouldSkipRoute(String location) {
    // Skip auth routes (login, register, dll)
    if (location.startsWith('/auth')) return true;

    // Skip onboarding
    if (location == '/') return true;
    // Skip nested routes with parameter/pattern (eg :id) — we don't want to persist templates
    if (location.contains(':') ||
        location.contains('[') ||
        location.contains(']')) {
      return true;
    }

    return false;
  }

  Future<void> _persistLastRoute(String route) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Normalize route: ensure it starts with '/'
      var normalized = route;
      if (!normalized.startsWith('/')) normalized = '/$normalized';

      // Map some legacy or short names to canonical routes
      if (normalized == '/notifications') normalized = '/profile/notifications';

      // Validasi route sebelum simpan — skip auth/onboarding/template routes
      if (normalized.isNotEmpty &&
          !normalized.startsWith('/auth') &&
          normalized != '/' &&
          !normalized.contains(':')) {
        await prefs.setString('last_route', normalized);
      }
    } catch (e) {
      print('Error saving last route: $e');
    }
  }
}
