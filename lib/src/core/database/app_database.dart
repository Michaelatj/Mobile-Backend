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
      version: 2, // ← Naikkan versi untuk migrasi aman
      onCreate: (db, version) async {
        // Versi 1: Buat semua tabel tanpa paymentMethod
        await _createTablesV1(db);

        // Versi 2: Tambahkan paymentMethod
        await _addPaymentMethodColumn(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _addPaymentMethodColumn(db);
        }
        // Tambahkan migrasi lain di sini nanti (contoh: if (oldVersion < 3) { ... })
      },
      onOpen: (db) async {
        // Hanya pastikan tabel utama ada (untuk fallback atau DB rusak)
        await _ensureTablesExist(db);
      },
    );

    return _db!;
  }

  /// Buat tabel dasar (versi 1)
  static Future<void> _createTablesV1(Database db) async {
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
        estimatedCost INTEGER
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

    await db.execute('''
      CREATE TABLE users(
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
  }

  /// Tambahkan kolom paymentMethod (hanya jika belum ada)
  static Future<void> _addPaymentMethodColumn(Database db) async {
    final exists = await _columnExists(db, 'bookings', 'paymentMethod');
    if (!exists) {
      await db.execute('ALTER TABLE bookings ADD COLUMN paymentMethod TEXT');
    }
  }

  /// Pastikan semua tabel ada (fallback untuk DB lama/rusak)
  static Future<void> _ensureTablesExist(Database db) async {
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
        createdAt INTEGER,
        date INTEGER,
        durationHours INTEGER,
        note TEXT,
        estimatedCost INTEGER,
        paymentMethod TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS messages(
        id TEXT PRIMARY KEY,
        providerId TEXT,
        userId TEXT,
        content TEXT,
        createdAt TEXT
      );
    ''');
  }

  /// Cek apakah kolom ada di tabel
  static Future<bool> _columnExists(Database db, String table, String column) async {
    final result = await db.rawQuery('PRAGMA table_info($table)');
    return result.any((col) => (col['name'] as String?) == column);
  }
}
