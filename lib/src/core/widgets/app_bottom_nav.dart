import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/user_role.dart';
import '../state/auth_state.dart';
import '../../features/orders/orders_page.dart';
import '../../features/profile/profile_page.dart';
import '../../features/community/community_page.dart';
import '../../features/training/training_page.dart';
import '../../features/partner/partner_dashboard_page.dart';
import '../../features/home/home_page.dart';

class AppBottomNavScaffold extends ConsumerStatefulWidget {
  final Widget child;
  const AppBottomNavScaffold({super.key, required this.child});

  @override
  ConsumerState<AppBottomNavScaffold> createState() =>
      _AppBottomNavScaffoldState();
}

class _AppBottomNavScaffoldState extends ConsumerState<AppBottomNavScaffold> {
  int _currentIndexFromLocation(String location, List<_TabItem> tabs) {
    final idx = tabs.indexWhere((t) => location.startsWith(t.path));
    return idx >= 0 ? idx : 0;
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final role = auth.user?.role ?? UserRole.customer;

    final customerTabs = <_TabItem>[
      _TabItem('Home', Icons.map_outlined, HomePage.routePath),
      _TabItem('Explore', Icons.explore_outlined,
          HomePage.routePath), // could lead to explore route
      _TabItem('Orders', Icons.receipt_long_outlined, OrdersPage.routePath),
      _TabItem('Favorites', Icons.favorite_border,
          HomePage.routePath), // placeholder
      _TabItem('Profile', Icons.person_outline, ProfilePage.routePath),
    ];
    final providerTabs = <_TabItem>[
      _TabItem('Orders', Icons.receipt_long_outlined, OrdersPage.routePath),
      _TabItem('Training', Icons.school_outlined, TrainingPage.routePath),
      _TabItem('Dashboard', Icons.dashboard_outlined,
          PartnerDashboardPage.routePath),
      _TabItem('Profile', Icons.person_outline, ProfilePage.routePath),
    ];

    final tabs = role == UserRole.customer ? customerTabs : providerTabs;
    final location = GoRouterState.of(context).uri.toString();
    final currentIdx = _currentIndexFromLocation(location, tabs);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIdx,
        onDestinationSelected: (idx) {
          context.go(tabs[idx].path);
        },
        destinations: tabs
            .map((t) =>
                NavigationDestination(icon: Icon(t.icon), label: t.label))
            .toList(),
      ),
    );
  }
}

class _TabItem {
  final String label;
  final IconData icon;
  final String path;
  _TabItem(this.label, this.icon, this.path);
}
