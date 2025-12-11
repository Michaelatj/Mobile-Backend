import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import '../models/review.dart';
import '../database/review_dao.dart';
import '../database/baseUrl.dart';

class ReviewRepository {
  static final String _endpoint = BaseUrl.reviews;

  /// Normalize providerId to handle multiple formats
  /// Examples: "providerId 51" → "51", "sp_1" → "sp_1", "51" → "51"
  static String _normalizeProviderId(String providerId) {
    // If contains spaces or special pattern like "providerId 123", extract number
    final match = RegExp(r'(\d+)$').firstMatch(providerId);
    if (match != null) {
      final extracted = match.group(1);
      if (extracted != null && extracted.isNotEmpty) {
        print('DEBUG: Normalized providerId "$providerId" → "$extracted"');
        return extracted;
      }
    }
    // Otherwise use as-is (e.g., "sp_1")
    print('DEBUG: ProviderId "$providerId" kept as-is');
    return providerId;
  }

  /// Parse createdAt timestamp
  /// Handles both seconds (10 digits) and milliseconds (13 digits)
  static DateTime _parseCreatedAt(dynamic v) {
    if (v == null) {
      print('DEBUG: createdAt is null, using current time');
      return DateTime.now();
    }

    // If integer, check if it's seconds (< 10 billion) or milliseconds
    if (v is int) {
      if (v < 10000000000) {
        // Less than 10 billion = likely seconds
        print('DEBUG: Detected createdAt in seconds ($v), converting to ms');
        return DateTime.fromMillisecondsSinceEpoch(v * 1000);
      } else {
        // Milliseconds
        print('DEBUG: Detected createdAt in milliseconds ($v)');
        return DateTime.fromMillisecondsSinceEpoch(v);
      }
    }

    // If string, try parsing as ISO8601 or int
    if (v is String) {
      try {
        return DateTime.parse(v);
      } catch (_) {
        final maybeInt = int.tryParse(v);
        if (maybeInt != null) {
          if (maybeInt < 10000000000) {
            print(
                'DEBUG: Parsed createdAt string "$v" as seconds, converting to ms');
            return DateTime.fromMillisecondsSinceEpoch(maybeInt * 1000);
          } else {
            print('DEBUG: Parsed createdAt string "$v" as milliseconds');
            return DateTime.fromMillisecondsSinceEpoch(maybeInt);
          }
        }
      }
    }

    print('WARNING: Could not parse createdAt "$v", using current time');
    return DateTime.now();
  }

  static Review _mapToReview(Map<String, dynamic> m) {
    // Normalize providerId from API response
    final rawProviderId = (m['providerId'] as String?) ?? '';
    final normalizedProviderId = _normalizeProviderId(rawProviderId);

    return Review(
      id: (m['id'] as Object?)?.toString() ??
          'r_${DateTime.now().millisecondsSinceEpoch}',
      providerId: normalizedProviderId,
      userId: (m['userId'] as String?) ?? 'guest',
      stars: (m['stars'] is num)
          ? (m['stars'] as num).toInt()
          : int.tryParse('${m['stars']}') ?? 0,
      comment: (m['comment'] as String?) ?? '',
      createdAt: _parseCreatedAt(m['createdAt']),
    );
  }

  /// Fetch reviews from remote API with fallback logic
  /// First tries direct query, then fallback if 404
  static Future<List<Review>> fetchReviews(String providerId) async {
    final normalizedId = _normalizeProviderId(providerId);

    try {
      // Attempt 1: Query parameter approach
      final uri1 = Uri.parse('$_endpoint?providerId=$normalizedId');
      print('DEBUG: Attempt 1 - Fetching from: $uri1');

      final res1 = await http.get(uri1);
      print('DEBUG: Response status code: ${res1.statusCode}');
      print(
          'DEBUG: Response body (first 200 chars): ${res1.body.substring(0, math.min(200, res1.body.length))}');

      if (res1.statusCode == 200) {
        return _parseAndPersistReviews(res1.body);
      }

      // Attempt 2: Fallback to path parameter if first failed (404)
      if (res1.statusCode == 404) {
        final uri2 = Uri.parse('$_endpoint/$normalizedId');
        print('DEBUG: Attempt 1 returned 404, fallback to path param: $uri2');

        final res2 = await http.get(uri2);
        print('DEBUG: Fallback response status code: ${res2.statusCode}');

        if (res2.statusCode == 200) {
          return _parseAndPersistReviews(res2.body);
        }
      }

      throw Exception(
          'HTTP ${res1.statusCode}: Both query and path attempts failed');
    } catch (e) {
      print('ERROR: fetchReviews failed for providerId="$providerId": $e');
      rethrow;
    }
  }

  /// Helper: Parse JSON response and persist to local DB
  static List<Review> _parseAndPersistReviews(String responseBody) {
    try {
      final List<dynamic> jsonList = json.decode(responseBody) as List<dynamic>;
      print('DEBUG: Parsed ${jsonList.length} reviews from API');

      final reviews = jsonList.map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        return _mapToReview(map);
      }).toList();

      // Persist to local DB (replace/insert) — optional offline cache
      for (final r in reviews) {
        try {
          ReviewDao.insertReview(r);
        } catch (e) {
          print('WARNING: Failed to persist review ${r.id} to local DB: $e');
        }
      }

      return reviews;
    } catch (e) {
      print('ERROR: Failed to parse reviews JSON: $e');
      rethrow;
    }
  }

  // post review to remote; persist returned record to local DB
  static Future<Review> postReview(Review review) async {
    try {
      final uri = Uri.parse(_endpoint);
      print('DEBUG: Posting review to: $uri');

      // Normalize providerId before sending
      final normalizedProviderId = _normalizeProviderId(review.providerId);

      final body = json.encode({
        'providerId': normalizedProviderId,
        'userId': review.userId,
        'stars': review.stars,
        'comment': review.comment,
        // send epoch ms to match MockAPI quicktype shape
        'createdAt': review.createdAt.millisecondsSinceEpoch,
      });
      print('DEBUG: Request body: $body');

      final res = await http.post(
        uri,
        body: body,
        headers: {'Content-Type': 'application/json'},
      );

      print('DEBUG: POST response status code: ${res.statusCode}');
      print('DEBUG: POST response body: ${res.body}');

      if (res.statusCode != 201 && res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}: POST review failed');
      }

      final map = Map<String, dynamic>.from(
          json.decode(res.body) as Map<String, dynamic>);
      final created = _mapToReview(map);

      // Persist to local DB
      try {
        await ReviewDao.insertReview(created);
        print('DEBUG: Review persisted to local DB with ID: ${created.id}');
      } catch (e) {
        print('WARNING: Failed to persist review to local DB: $e');
      }

      return created;
    } catch (e) {
      print('ERROR: postReview failed: $e');
      rethrow;
    }
  }

  /// Delete review from remote API, then remove from local DB cache.
  /// This ensures the API record is removed and local state follows.
  static Future<void> deleteReview(String id) async {
    try {
      final uri = Uri.parse('$_endpoint/$id');
      print('DEBUG: Deleting review at: $uri');

      final res = await http.delete(uri);
      print('DEBUG: DELETE response status code: ${res.statusCode}');

      if (res.statusCode != 200 && res.statusCode != 204) {
        throw Exception(
            'HTTP ${res.statusCode}: DELETE review failed - ${res.body}');
      }

      // Remove from local DB cache as well
      try {
        await ReviewDao.deleteReview(id);
        print('DEBUG: Deleted review $id from local DB');
      } catch (e) {
        print(
            'WARNING: Failed to delete review $id from local DB after remote delete: $e');
      }
    } catch (e) {
      print('ERROR: deleteReview failed for id=$id: $e');
      rethrow;
    }
  }
}
