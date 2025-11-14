import 'app_database.dart';
import '../models/message.dart';
import 'package:sqflite/sqflite.dart';

class MessageDao {
  static Future<void> insertMessage(Message message) async {
    final db = await AppDatabase.getDb();
    await db.insert(
      'messages',
      {
        'id': message.id,
        'providerId': message.providerId,
        'userId': message.userId,
        'content': message.content,
        'createdAt': message.createdAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Message>> getMessagesByProviderUser(
      String providerId, String userId) async {
    final db = await AppDatabase.getDb();
    final maps = await db.query(
      'messages',
      where: 'providerId = ? AND userId = ?',
      whereArgs: [providerId, userId],
      orderBy: 'createdAt ASC',
    );
    return maps
        .map((m) => Message(
              id: m['id'] as String,
              providerId: m['providerId'] as String,
              userId: m['userId'] as String,
              content: m['content'] as String,
              createdAt: DateTime.parse(m['createdAt'] as String),
            ))
        .toList();
  }
}
