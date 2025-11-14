// core/models/booking.dart
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart'; // untuk debugPrint

enum BookingStatus {
  pending,
  inProgress,
  completed,
  cancelled,
}

class Booking {
  final String id;
  final String userId;
  final String providerId;
  final BookingStatus status;
  final DateTime createdAt;
  final DateTime date;
  final int durationHours;
  final String? note;
  final int? estimatedCost;
  final String? paymentMethod;

  Booking({
    String? id,
    required this.userId,
    required this.providerId,
    this.status = BookingStatus.pending,
    DateTime? createdAt,
    required this.date,
    required this.durationHours,
    this.note,
    this.estimatedCost,
    this.paymentMethod,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();


      Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'providerId': providerId,
      'status': status.name, // ← LEBIH BAIK
      'createdAt': createdAt.millisecondsSinceEpoch,
      'date': date.millisecondsSinceEpoch,
      'durationHours': durationHours,
      'note': note,
      'estimatedCost': estimatedCost,
      'paymentMethod': paymentMethod,
    };
  }

  factory Booking.fromMap(Map<String, dynamic> map) {
    int parseTimestamp(dynamic value) {
      if (value is int) return value;
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed == null) debugPrint('Invalid timestamp: $value');
        return parsed ?? 0;
      }
      debugPrint('Unexpected type: ${value.runtimeType}');
      return DateTime.now().millisecondsSinceEpoch;
    }

    return Booking(
      id: map['id'] as String? ?? const Uuid().v4(),
      userId: map['userId'] as String,
      providerId: map['providerId'] as String,
      status: BookingStatus.values.firstWhere(
        (e) => e.name == (map['status'] as String?),
        orElse: () => BookingStatus.pending,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(parseTimestamp(map['createdAt'])),
      date: DateTime.fromMillisecondsSinceEpoch(parseTimestamp(map['date'])),
      durationHours: map['durationHours'] as int? ?? 1,
      note: map['note'] as String?,
      estimatedCost: map['estimatedCost'] as int?,
      paymentMethod: map['paymentMethod'] as String?,
    );
  }}