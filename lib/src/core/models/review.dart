import 'dart:convert';

class Review {
  final String id;
  final String providerId;
  final String userId;
  final int stars;
  final String comment;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.providerId,
    required this.userId,
    required this.stars,
    required this.comment,
    required this.createdAt,
  });

  // Parse from Map (DB record or remote JSON object)
  factory Review.fromMap(Map<String, dynamic> m) {
    DateTime parseCreatedAt(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      if (v is String) {
        final asInt = int.tryParse(v);
        if (asInt != null) return DateTime.fromMillisecondsSinceEpoch(asInt);
        try {
          return DateTime.parse(v);
        } catch (_) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    final id = (m['id'] ?? m['Id'] ?? '')?.toString() ?? '';
    return Review(
      id: id.isNotEmpty ? id : 'r_${DateTime.now().millisecondsSinceEpoch}',
      providerId:
          (m['providerId'] as String?) ?? (m['provider_id'] as String?) ?? '',
      userId: (m['userId'] as String?) ?? (m['user_id'] as String?) ?? 'guest',
      stars: (m['stars'] is num)
          ? (m['stars'] as num).toInt()
          : int.tryParse('${m['stars']}') ?? 0,
      comment: (m['comment'] as String?) ?? '',
      createdAt: parseCreatedAt(m['createdAt'] ?? m['created_at']),
    );
  }

  // Convert to Map (useful for DB insert / HTTP body)
  Map<String, dynamic> toMap() => {
        'id': id,
        'providerId': providerId,
        'userId': userId,
        'stars': stars,
        'comment': comment,
        // store/send createdAt as epoch ms for compatibility with mockapi
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  // JSON helpers
  factory Review.fromJson(String source) =>
      Review.fromMap(json.decode(source) as Map<String, dynamic>);
  String toJson() => json.encode(toMap());

  // convenience: list parse/serialize
  static List<Review> listFromJson(String source) {
    final List<dynamic> data = json.decode(source) as List<dynamic>;
    return data
        .map((e) => Review.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static String listToJson(List<Review> list) =>
      json.encode(list.map((e) => e.toMap()).toList());
}
