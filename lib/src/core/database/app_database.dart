import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static Database? _db;

  static Future<Database> getDb() async {
    if (_db != null) return _db!;
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'bantuin.db');
    print('DB path: $path');

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
      },
    );

    return _db!;
  }
}
