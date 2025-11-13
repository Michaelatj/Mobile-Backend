import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/service_provider.dart';
import '../database/provider_dao.dart'; // Ganti ke ProviderDao
import '../models/review.dart';
import '../database/review_dao.dart';
import '../database/booking_dao.dart';
import '../models/booking.dart';

final listViewToggleProvider = StateProvider<bool>((ref) => false);
final categoryFilterProvider = StateProvider<String?>((ref) => null);
final searchQueryProvider = StateProvider<String>((ref) => '');

final nearbyProvidersProvider =
    FutureProvider<List<ServiceProvider>>((ref) async {
  final category = ref.watch(categoryFilterProvider);
  final query = ref.watch(searchQueryProvider);

  final all = await ProviderDao.getAllProviders();
  return all.where((p) {
    final byCat = category == null || p.category == category;
    final byQuery =
        query.isEmpty || p.name.toLowerCase().contains(query.toLowerCase());
    return byCat && byQuery;
  }).toList();
});

// provider by id (used to invalidate from review section)
final providerByIdProvider =
    FutureProvider.family<ServiceProvider?, String>((ref, id) {
  return ProviderDao.getProviderById(id);
});

final reviewsByProviderProvider =
    FutureProvider.family<List<Review>, String>((ref, id) async {
  return ReviewDao.getReviewsByProvider(id);
});

// orders provider (per user)
final ordersProvider =
    FutureProvider.family<List<Booking>, String>((ref, userId) {
  return BookingDao.getBookingsByUser(userId);
});

// Provider untuk menyimpan last route
// Hanya tracks routes yang valid (bukan auth, onboarding, atau dengan dynamic params)
final lastRouteProvider = StateProvider<String>((ref) => '/home');

// Flag untuk menandai apakah last-route sudah diaplikasikan setelah start
final lastRouteAppliedProvider = StateProvider<bool>((ref) => false);

/// Fungsi untuk validasi apakah route valid untuk di-track
bool isValidLastRoute(String route) {
  // Harus ada (tidak kosong)
  if (route.isEmpty) return false;

  // Normalize missing leading slash (some saved values may lack it)
  if (!route.startsWith('/')) route = '/$route';

  // Tidak boleh auth flow
  if (route.startsWith('/auth')) return false;

  // Tidak boleh onboarding
  if (route == '/') return false;

  // Tidak boleh memiliki dynamic parameter
  if (route.contains(':') || route.contains('[') || route.contains(']')) {
    return false;
  }

  // Basic whitelist of valid route prefixes in this app
  const allowedPrefixes = [
    '/home',
    '/profile',
    '/provider',
    '/booking',
    '/orders',
    '/training',
    '/community',
    '/help',
    '/partner',
  ];

  final ok = allowedPrefixes.any(
      (p) => route == p || route.startsWith(p + '/') || route.startsWith(p));
  return ok;
}
