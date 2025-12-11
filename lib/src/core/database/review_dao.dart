import 'package:flutter/foundation.dart';
import 'app_database.dart';
import 'package:sqflite/sqflite.dart';
import '../models/review.dart';

class ReviewDao {
  static Future<void> insertReview(Review r) async {
    final db = await AppDatabase.getDb();
    debugLog(
        'INSERT review: id=${r.id}, providerId=${r.providerId}, userId=${r.userId}');
    try {
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
      debugLog('INSERT review SUCCESS: id=${r.id}');
    } catch (e) {
      debugLog('INSERT review ERROR: id=${r.id}, error=$e');
      rethrow;
    }
  }

  static Future<List<Review>> getReviewsByProvider(String providerId) async {
    final db = await AppDatabase.getDb();
    debugLog('GET reviews for provider: $providerId');
    try {
      final maps = await db.query(
        'reviews',
        where: 'providerId = ?',
        whereArgs: [providerId],
        orderBy: 'createdAt DESC',
      );
      debugLog(
          'GET reviews SUCCESS: found ${maps.length} reviews for provider $providerId');
      return maps.map((m) => Review.fromMap(m)).toList();
    } catch (e) {
      debugLog('GET reviews ERROR: providerId=$providerId, error=$e');
      rethrow;
    }
  }

  static Future<void> updateReview(Review r) async {
    final db = await AppDatabase.getDb();
    debugLog('UPDATE review: id=${r.id}, providerId=${r.providerId}');
    try {
      final changed = await db.update(
        'reviews',
        {
          'providerId': r.providerId,
          'userId': r.userId ?? 'guest',
          'stars': r.stars,
          'comment': r.comment ?? '',
          'createdAt': r.createdAt.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [r.id],
      );
      debugLog('UPDATE review SUCCESS: id=${r.id}, changed=$changed rows');
    } catch (e) {
      debugLog('UPDATE review ERROR: id=${r.id}, error=$e');
      rethrow;
    }
  }

  static Future<void> deleteReview(String id) async {
    final db = await AppDatabase.getDb();
    debugLog('DELETE review: id=$id, checking if exists...');
    try {
      // First verify the review exists before deletion
      final existing =
          await db.query('reviews', where: 'id = ?', whereArgs: [id], limit: 1);
      if (existing.isEmpty) {
        debugLog(
            'DELETE review WARN: review id=$id does NOT exist in DB (possible duplicate delete or race condition)');
      } else {
        debugLog('DELETE review: found review id=$id, proceeding with delete');
      }

      final deleted =
          await db.delete('reviews', where: 'id = ?', whereArgs: [id]);
      debugLog('DELETE review SUCCESS: id=$id, deleted=$deleted rows');

      if (deleted == 0) {
        debugLog(
            'DELETE review WARN: delete returned 0 rows (review may have already been deleted or id mismatch)');
      }
    } catch (e) {
      debugLog(
          'DELETE review ERROR: id=$id, error=$e, stacktrace: ${StackTrace.current}');
      rethrow;
    }
  }

  static void debugLog(String msg) {
    // Use debugPrint for non-blocking, non-production logging
    debugPrint('[ReviewDao] $msg');
  }
}
