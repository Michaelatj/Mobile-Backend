import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Local SQLite Database Manager
///
/// DATABASE USAGE EXPLANATION:
/// ============================
/// This app uses sqflite for persistent local caching across all platforms.
///
/// Storage Location by Platform:
/// - Android:   /data/data/com.example.bantuin_silvani/databases/bantuin.db
/// - iOS:       App Documents folder (private to app)
/// - Windows:   Uses sqflite_common_ffi; printed path on first access
/// - macOS:     Uses sqflite_common_ffi; printed path on first access
///
/// Usage Strategy:
/// - On app launch, fetches from remote API (Bookings, Reviews, Providers, Messages, Users)
/// - Stores fetched data in local DB tables for offline access
/// - On network error, reads from local cache (fallback strategy)
/// - Local data refreshed on each successful API fetch (not persistent cache)
///
/// Tables:
/// - providers:  Service providers (cached from API)
/// - reviews:    User reviews for providers (cached from API)
/// - bookings:   User booking history (cached from API)
/// - messages:   Chat messages (cached from API)
/// - users:      User profiles (cached from API)
///
/// Future Enhancement:
/// - Implement incremental sync with Firebase Realtime Database
/// - Add timestamp-based cache invalidation (refresh if > 24 hours old)
class AppDatabase {
  static Database? _db;

  static Future<Database> getDb() async {
    if (_db != null) return _db!;
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'bantuin.db');
    print('DEBUG: SQLite database initialized');
    print('DEBUG: DB path: $path');
    print('DEBUG: DB storage mode: FILE-BASED (persists offline data)');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE providers(
            id TEXT PRIMARY KEY,
            name TEXT,
            category TEXT,
            rating REAL,
            distanceKm REAL,
            description TEXT,
            priceFrom INTEGER
          );
        ''');

        await db.execute('''
          CREATE TABLE reviews(
            id TEXT PRIMARY KEY,
            providerId TEXT,
            userId TEXT,
            stars INTEGER,
            comment TEXT,
            createdAt TEXT
          );
        ''');

        await db.execute('''
          CREATE TABLE bookings(
            id TEXT PRIMARY KEY,
            userId TEXT,
            providerId TEXT,
            status TEXT,
            createdAt TEXT,
            date TEXT,
            durationHours INTEGER,
            note TEXT,
            estimatedCost INTEGER,
            paymentMethod TEXT
          );
        ''');

        await db.execute('''
          CREATE TABLE messages(
            id TEXT PRIMARY KEY,
            providerId TEXT,
            userId TEXT,
            content TEXT,
            createdAt TEXT
          );
        ''');

        // create users table on fresh DB
        await db.execute('''
          CREATE TABLE users(
            id TEXT PRIMARY KEY,
            name TEXT,
            email TEXT UNIQUE,
            password TEXT,
            role TEXT,
            firebaseUid TEXT,
            photoUrl TEXT,
            locationLabel TEXT,
            createdAt TEXT
          );
        ''');
      },
      onOpen: (db) async {
        // ensure tables exist for older DBs
        await db.execute('''
          CREATE TABLE IF NOT EXISTS users(
            id TEXT PRIMARY KEY,
            name TEXT,
            email TEXT UNIQUE,
            password TEXT,
            role TEXT,
            photoUrl TEXT,
            locationLabel TEXT,
            createdAt TEXT
          );
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS providers(
            id TEXT PRIMARY KEY,
            name TEXT,
            category TEXT,
            rating REAL,
            distanceKm REAL,
            description TEXT,
            priceFrom INTEGER
          );
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS reviews(
            id TEXT PRIMARY KEY,
            providerId TEXT,
            userId TEXT,
            stars INTEGER,
            comment TEXT,
            createdAt TEXT
          );
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS bookings(
            id TEXT PRIMARY KEY,
            userId TEXT,
            providerId TEXT,
            status TEXT,
            createdAt TEXT,
            date TEXT,
            durationHours INTEGER,
            note TEXT,
            estimatedCost INTEGER
          );
        ''');

        // add paymentMethod column if missing (safe ALTER)
        try {
          await db
              .execute("ALTER TABLE bookings ADD COLUMN paymentMethod TEXT");
        } catch (_) {
          // ignore if already exists
        }

        // add firebaseUid column to users table for older DBs if missing
        try {
          await db.execute("ALTER TABLE users ADD COLUMN firebaseUid TEXT");
        } catch (_) {
          // ignore if already exists
        }
      },
    );

    return _db!;
  }
}
