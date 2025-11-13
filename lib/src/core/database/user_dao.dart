import 'app_database.dart';
import 'package:sqflite/sqflite.dart';

class UserDao {
  static Future<void> insertUser(Map<String, dynamic> user) async {
    final db = await AppDatabase.getDb();
    await db.insert('users', user,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<Map<String, dynamic>?> findUserByEmail(String email) async {
    final db = await AppDatabase.getDb();
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  static Future<Map<String, dynamic>?> findUser(
      String email, String password) async {
    final db = await AppDatabase.getDb();
    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  static Future<bool> emailExists(String email) async {
    final db = await AppDatabase.getDb();
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  static Future<void> updateUserProfile({
    required String id,
    required String name,
    String? locationLabel,
    String? photoUrl,
  }) async {
    final db = await AppDatabase.getDb();
    await db.update(
      'users',
      {
        'name': name,
        'locationLabel': locationLabel ?? '',
        'photoUrl': photoUrl ?? '',
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
