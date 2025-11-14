import 'package:flutter/material.dart';
import 'package:flutter_application_1/src/core/database/dummy_data.dart';
import 'package:flutter_application_1/src/core/database/provider_dao.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'src/core/database/review_dao.dart';
import 'src/core/models/review.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/app.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'src/core/state/providers.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // PATCH: hanya inisialisasi sqflite_ffi di desktop
  if (!Platform.isAndroid && !Platform.isIOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize Firebase with error handling (prevent duplicate-app crashes)
  try {
    await Firebase.initializeApp(
        options: const FirebaseOptions(
            apiKey: "AIzaSyCcyJNJ8ovtr1ve2XZVqvhmp-bqokZ9b6k",
            authDomain: "praktikum-firebase-m06-m07.firebaseapp.com",
            projectId: "praktikum-firebase-m06-m07",
            storageBucket: "praktikum-firebase-m06-m07.firebasestorage.app",
            messagingSenderId: "620349393151",
            appId: "1:620349393151:web:c5c114c866552f643024ca",
            measurementId: "G-48G4T7MZ57"));
    print('DEBUG: Firebase initialized successfully');
  } catch (e) {
    // Firebase app already exists (hot reload/restart). This is OK.
    if (e.toString().contains('duplicate-app')) {
      print(
          'DEBUG: Firebase already initialized (duplicate-app), continuing...');
    } else {
      print('WARNING: Firebase init error: $e');
    }
  }

  // Initialize Firebase Analytics (safe if Firebase init failed)
  try {
    final analytics = FirebaseAnalytics.instance;
    await analytics.setAnalyticsCollectionEnabled(true);
    print('DEBUG: Firebase Analytics enabled');
  } catch (e) {
    print('WARNING: Analytics init failed: $e');
  }

  // initialize intl locale data for 'id_ID'
  await initializeDateFormatting('id_ID');

  // Restore last route dari SharedPreferences dan setup provider override
  var lastRoute = '/home'; // safe default
  try {
    final prefs = await SharedPreferences.getInstance();
    lastRoute = prefs.getString('last_route') ?? '/home';
    print('Restored last_route: $lastRoute');

    // Normalize restored value: ensure leading '/'
    if (!lastRoute.startsWith('/')) lastRoute = '/$lastRoute';

    // Map some legacy/short names to canonical routes
    if (lastRoute == '/notifications') {
      lastRoute = '/profile/notifications';
      await prefs.setString('last_route', lastRoute);
      print('DEBUG: Normalized saved /notifications → $lastRoute');
    }

    // If the stored route is a template (contains ':') or otherwise invalid,
    // clear it so the app doesn't stay stuck on a template path.
    if (lastRoute.contains(':')) {
      print(
          'DEBUG: Detected template route in cache ($lastRoute), clearing to /home');
      lastRoute = '/home';
      await prefs.setString('last_route', '/home');
    }

    // CLEAR CACHE: If cache last route explicitly known to be problematic, reset to /home
    const invalidCacheRoutes = ['/partner', '/training'];
    if (invalidCacheRoutes.contains(lastRoute)) {
      print(
          'DEBUG: Clearing invalid cached route: $lastRoute → resetting to /home');
      lastRoute = '/home';
      await prefs.setString('last_route', '/home');
    }
  } catch (e) {
    print('WARNING: SharedPreferences error: $e');
    lastRoute = '/home';
  }

  // SEED DUMMY DATA JIKA DB MASIH KOSONG
  try {
    final providers = await ProviderDao.getAllProviders();
    if (providers.isEmpty) {
      final dummy = await DummyData.seedProviders();
      for (final p in dummy) {
        await ProviderDao.insertProvider(p);
      }

      final inserted = await ProviderDao.getAllProviders();
      final dummyReviews = await DummyData.seedReviews(inserted);
      for (final rv in dummyReviews) {
        await ReviewDao.insertReview(rv);
      }

      for (final sp in inserted) {
        final reviews = await ReviewDao.getReviewsByProvider(sp.id);
        final avg = reviews.isEmpty
            ? sp.rating
            : reviews.map((r) => r.stars).reduce((a, b) => a + b) /
                reviews.length;
        await ProviderDao.updateProviderRating(
            sp.id, double.parse(avg.toStringAsFixed(1)));
      }
      print('DEBUG: Database seeded with dummy data');
    }
  } catch (e) {
    print('WARNING: Database seeding error: $e');
  }

  // Override lastRouteProvider dengan nilai dari SharedPreferences
  runApp(
    ProviderScope(
      overrides: [
        lastRouteProvider.overrideWith((ref) => lastRoute),
      ],
      child: const LayananLokalApp(),
    ),
  );
}
