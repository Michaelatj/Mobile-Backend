import 'package:flutter/foundation.dart';

@immutable
class Message {
  final String id;
  final String providerId;
  final String userId;
  final String content;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.providerId,
    required this.userId,
    required this.content,
    required this.createdAt,
  });

  factory Message.fromMap(Map<String, dynamic> map) => Message(
        id: map['id'] as String,
        providerId: map['providerId'] as String,
        userId: map['userId'] as String,
        content: map['content'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'providerId': providerId,
        'userId': userId,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
      };
}
