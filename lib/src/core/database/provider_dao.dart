import 'app_database.dart';
import '../models/service_provider.dart';
import 'package:sqflite/sqflite.dart';

class ProviderDao {
  static Future<void> insertProvider(ServiceProvider p) async {
    final db = await AppDatabase.getDb();
    await db.insert(
      'providers',
      p.toMap(),
    );
  }

  static Future<void> updateProvider(ServiceProvider p) async {
    final db = await AppDatabase.getDb();
    await db.update(
      'providers',
      p.toMap(),
      where: 'id = ?',
      whereArgs: [p.id],
    );
  }

  // helper to update only rating quickly
  static Future<void> updateProviderRating(String id, double rating) async {
    final db = await AppDatabase.getDb();
    await db.update(
      'providers',
      {'rating': rating},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> deleteProvider(String id) async {
    final db = await AppDatabase.getDb();
    await db.delete(
      'providers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<ServiceProvider?> getProviderById(String id) async {
    final db = await AppDatabase.getDb();
    final maps = await db.query(
      'providers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return ServiceProvider.fromMap(maps.first);
    }
    return null;
  }

  static Future<List<ServiceProvider>> getAllProviders() async {
    final db = await AppDatabase.getDb();
    final maps = await db.query('providers');
    return maps.map((m) => ServiceProvider.fromMap(m)).toList();
  }
}
