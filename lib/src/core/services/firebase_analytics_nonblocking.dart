import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Non-blocking analytics helpers. Use these to log events without
/// blocking UI or throwing to callers. Errors are caught and logged.
class FirebaseAnalyticsNonBlocking {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static Future<void> logBookingCanceledEvent({
    required String userId,
    required String bookingId,
    required String providerId,
    required String cancelReason,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'booking_canceled',
        parameters: {
          'user_id': userId,
          'booking_id': bookingId,
          'provider_id': providerId,
          'cancel_reason': cancelReason,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      debugPrint('DEBUG: booking_canceled logged');
    } catch (e) {
      // swallow errors — analytics must not fail the main flow
      debugPrint('WARN: analytics booking_canceled failed: $e');
    }
  }

  static Future<void> logLoginEvent({
    required String userId,
    required String email,
    required String loginMethod,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'login',
        parameters: {
          'user_id': userId,
          'email': email,
          'method': loginMethod,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      debugPrint('DEBUG: login event logged');
    } catch (e) {
      debugPrint('WARN: analytics login failed: $e');
    }
  }
}
