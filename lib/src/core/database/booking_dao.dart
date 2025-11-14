// core/database/booking_dao.dart
import 'package:sqflite/sqflite.dart';
import 'app_database.dart';
import '../models/booking.dart';

class BookingDao {
  /// Insert booking ke database lokal
  static Future<void> insertBooking(Booking b) async {
    final db = await AppDatabase.getDb();
    await db.insert(
      'bookings',
      {
        'id': b.id,
        'userId': b.userId,
        'providerId': b.providerId,
        'status': b.status.name,
        'createdAt': b.createdAt.millisecondsSinceEpoch, // ← MILISECOND (INTEGER)
        'date': b.date.millisecondsSinceEpoch,           // ← MILISECOND (INTEGER)
        'durationHours': b.durationHours,
        'note': b.note ?? '',
        'estimatedCost': b.estimatedCost,
        'paymentMethod': b.paymentMethod ?? '',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Ambil semua booking milik user
  static Future<List<Booking>> getBookingsByUser(String userId) async {
    final db = await AppDatabase.getDb();
    final List<Map<String, dynamic>> maps = await db.query(
      'bookings',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return Booking.fromMap(maps[i]);
    });
  }

  /// Update status booking
  static Future<void> updateBookingStatus(String id, BookingStatus status) async {
    final db = await AppDatabase.getDb();
    await db.update(
      'bookings',
      {'status': status.name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// (Opsional) Ambil satu booking
  static Future<Booking?> getBookingById(String id) async {
    final db = await AppDatabase.getDb();
    final maps = await db.query(
      'bookings',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Booking.fromMap(maps.first);
  }
}
