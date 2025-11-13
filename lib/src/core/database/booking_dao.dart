import 'app_database.dart';
import '../models/booking.dart';
import 'package:sqflite/sqflite.dart';

class BookingDao {
  static Future<void> insertBooking(Booking b) async {
    final db = await AppDatabase.getDb();
    await db.insert(
      'bookings',
      {
        'id': b.id,
        'userId': b.userId,
        'providerId': b.providerId,
        'status': b.status.name,
        'createdAt': b.createdAt.toIso8601String(),
        'date': b.date.toIso8601String(),
        'durationHours': b.durationHours,
        'note': b.note ?? '',
        'estimatedCost': b.estimatedCost,
        'paymentMethod': b.paymentMethod ?? '',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Booking>> getBookingsByUser(String userId) async {
    final db = await AppDatabase.getDb();
    final maps = await db.query(
      'bookings',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
    return maps.map((m) => Booking.fromMap(m)).toList();
  }

  // accept BookingStatus directly to avoid caller passing wrong type
  static Future<void> updateBookingStatus(
      String id, BookingStatus status) async {
    final db = await AppDatabase.getDb();
    await db.update('bookings', {'status': status.name},
        where: 'id = ?', whereArgs: [id]);
  }
}
