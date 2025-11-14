import 'app_database.dart';
import 'package:sqflite/sqflite.dart';
import '../models/review.dart';

class ReviewDao {
  static Future<void> insertReview(Review r) async {
    final db = await AppDatabase.getDb();
    await db.insert(
      'reviews',
      {
        'id': r.id,
        'providerId': r.providerId,
        'userId': r.userId ?? 'guest',
        'stars': r.stars,
        'comment': r.comment ?? '',
        'createdAt': r.createdAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Review>> getReviewsByProvider(String providerId) async {
    final db = await AppDatabase.getDb();
    final maps = await db.query(
      'reviews',
      where: 'providerId = ?',
      whereArgs: [providerId],
      orderBy: 'createdAt DESC',
    );
    return maps.map((m) => Review.fromMap(m)).toList();
  }

  static Future<void> updateReview(Review r) async {
    final db = await AppDatabase.getDb();
    await db.update(
        'reviews',
        {
          'providerId': r.providerId,
          'userId': r.userId ?? 'guest',
          'stars': r.stars,
          'comment': r.comment ?? '',
          'createdAt': r.createdAt.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [r.id]);
  }

  static Future<void> deleteReview(String id) async {
    final db = await AppDatabase.getDb();
    await db.delete('reviews', where: 'id = ?', whereArgs: [id]);
  }
}
