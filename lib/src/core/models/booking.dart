enum BookingStatus { pending, inProgress, completed, cancelled }

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
  final String? paymentMethod; // NEW

  Booking({
    required this.id,
    required this.userId,
    required this.providerId,
    required this.status,
    required this.createdAt,
    required this.date,
    required this.durationHours,
    this.note,
    this.estimatedCost,
    this.paymentMethod,
  });

  factory Booking.fromMap(Map<String, dynamic> m) {
    final statusStr = (m['status'] as String?) ?? BookingStatus.pending.name;
    final status = BookingStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => BookingStatus.pending,
    );

    DateTime parseDt(dynamic v) {
      if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      if (v is String) {
        try {
          return DateTime.parse(v);
        } catch (_) {
          return DateTime.fromMillisecondsSinceEpoch(0);
        }
      }
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    return Booking(
      id: m['id'] as String,
      userId: m['userId'] as String,
      providerId: m['providerId'] as String,
      status: status,
      createdAt: parseDt(m['createdAt']),
      date: parseDt(m['date']),
      durationHours: (m['durationHours'] is num)
          ? (m['durationHours'] as num).toInt()
          : int.tryParse('${m['durationHours']}') ?? 1,
      note: m['note'] as String?,
      estimatedCost: (m['estimatedCost'] is num)
          ? (m['estimatedCost'] as num).toInt()
          : (m['estimatedCost'] != null
              ? int.tryParse('${m['estimatedCost']}')
              : null),
      paymentMethod: (m['paymentMethod'] as String?) ?? null,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'providerId': providerId,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'date': date.toIso8601String(),
        'durationHours': durationHours,
        'note': note ?? '',
        'estimatedCost': estimatedCost,
        'paymentMethod': paymentMethod,
      };
}
