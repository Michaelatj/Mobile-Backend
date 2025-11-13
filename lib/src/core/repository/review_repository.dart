import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/review.dart';
import '../database/review_dao.dart';
import '../database/baseUrl.dart';

class ReviewRepository {
  static final String _endpoint = BaseUrl.reviews;

  static DateTime _parseCreatedAt(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is String) {
      try {
        return DateTime.parse(v);
      } catch (_) {
        final maybeInt = int.tryParse(v);
        if (maybeInt != null)
          return DateTime.fromMillisecondsSinceEpoch(maybeInt);
      }
    }
    return DateTime.now();
  }

  static Review _mapToReview(Map<String, dynamic> m) {
    return Review(
      id: (m['id'] as Object?)?.toString() ??
          'r_${DateTime.now().millisecondsSinceEpoch}',
      providerId: (m['providerId'] as String?) ?? '',
      userId: (m['userId'] as String?) ?? 'guest',
      stars: (m['stars'] is num)
          ? (m['stars'] as num).toInt()
          : int.tryParse('${m['stars']}') ?? 0,
      comment: (m['comment'] as String?) ?? '',
      createdAt: _parseCreatedAt(m['createdAt']),
    );
  }

  // fetch reviews from remote; on success persist to local DB
  static Future<List<Review>> fetchReviews(String providerId) async {
    final uri = Uri.parse('$_endpoint?providerId=$providerId');
    final res = await http.get(uri);
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    final List<dynamic> jsonList = json.decode(res.body) as List<dynamic>;
    final reviews = jsonList.map((e) {
      final map = Map<String, dynamic>.from(e as Map);
      return _mapToReview(map);
    }).toList();

    // persist to local DB (replace/insert)
    for (final r in reviews) {
      try {
        await ReviewDao.insertReview(r);
      } catch (_) {}
    }
    return reviews;
  }

  // post review to remote; persist returned record to local DB
  static Future<Review> postReview(Review review) async {
    final uri = Uri.parse(_endpoint);
    final body = json.encode({
      'providerId': review.providerId,
      'userId': review.userId,
      'stars': review.stars,
      'comment': review.comment,
      // send epoch ms to match MockAPI quicktype shape
      'createdAt': review.createdAt.millisecondsSinceEpoch,
    });
    final res = await http
        .post(uri, body: body, headers: {'Content-Type': 'application/json'});
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}');
    }
    final map = Map<String, dynamic>.from(
        json.decode(res.body) as Map<String, dynamic>);
    final created = _mapToReview(map);
    try {
      await ReviewDao.insertReview(created);
    } catch (_) {}
    return created;
  }
}
