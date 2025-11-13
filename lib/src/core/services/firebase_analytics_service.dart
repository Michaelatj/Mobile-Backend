import 'package:firebase_analytics/firebase_analytics.dart';

/// Service untuk mengirim event ke Firebase Analytics
/// Digunakan untuk tracking user behavior dan button clicks
class FirebaseAnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Event: User login button clicked
  /// Tracks: userId, timestamp, login_method
  static Future<void> logLoginEvent({
    required String userId,
    String loginMethod = 'email', // email, google, facebook
  }) async {
    try {
      await _analytics.logEvent(
        name: 'button_login_clicked',
        parameters: {
          'user_id': userId,
          'login_method': loginMethod,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      print(
          'DEBUG: Analytics event sent - button_login_clicked for user: $userId');
    } catch (e) {
      print('ERROR: Failed to log login event: $e');
    }
  }

  /// Event: Profile edit button clicked
  /// Tracks: userId, field_changed (name, location, photo), old_value, new_value
  static Future<void> logProfileEditEvent({
    required String userId,
    required String fieldChanged,
    String? oldValue,
    String? newValue,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'button_profile_edit_clicked',
        parameters: {
          'user_id': userId,
          'field_changed': fieldChanged,
          'old_value': oldValue ?? 'N/A',
          'new_value': newValue ?? 'N/A',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      print(
          'DEBUG: Analytics event sent - button_profile_edit_clicked for field: $fieldChanged');
    } catch (e) {
      print('ERROR: Failed to log profile edit event: $e');
    }
  }

  /// Event: Booking submit button clicked
  /// Tracks: userId, providerId, service_type, total_amount, duration_hours
  static Future<void> logBookingSubmitEvent({
    required String userId,
    required String providerId,
    required String serviceType,
    required int totalAmount,
    required int durationHours,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'button_booking_submit_clicked',
        parameters: {
          'user_id': userId,
          'provider_id': providerId,
          'service_type': serviceType,
          'total_amount': totalAmount.toString(),
          'duration_hours': durationHours.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      print('DEBUG: Analytics event sent - button_booking_submit_clicked');
    } catch (e) {
      print('ERROR: Failed to log booking submit event: $e');
    }
  }

  /// Event: Notifications button clicked / Notifications page viewed
  /// Tracks: userId, notification_count, notification_types
  static Future<void> logNotificationsViewEvent({
    required String userId,
    int notificationCount = 0,
    List<String>? notificationTypes,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'button_notifications_clicked',
        parameters: {
          'user_id': userId,
          'notification_count': notificationCount.toString(),
          'notification_types': (notificationTypes ?? []).join(','),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      print('DEBUG: Analytics event sent - button_notifications_clicked');
    } catch (e) {
      print('ERROR: Failed to log notifications view event: $e');
    }
  }

  /// Event: Logout button clicked
  /// Tracks: userId, session_duration_minutes
  static Future<void> logLogoutEvent({
    required String userId,
    int sessionDurationMinutes = 0,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'button_logout_clicked',
        parameters: {
          'user_id': userId,
          'session_duration_minutes': sessionDurationMinutes.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      print(
          'DEBUG: Analytics event sent - button_logout_clicked for user: $userId');
    } catch (e) {
      print('ERROR: Failed to log logout event: $e');
    }
  }

  /// Event: Custom screen view (page opened)
  /// Tracks: screen_name, userId
  static Future<void> logScreenView({
    required String screenName,
    required String userId,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        parameters: {
          'user_id': userId,
        },
      );
      print('DEBUG: Analytics screen view - $screenName');
    } catch (e) {
      print('ERROR: Failed to log screen view: $e');
    }
  }

  /// Event: API/HTTP Request call
  /// Tracks: endpoint, method, status_code, response_time_ms
  static Future<void> logApiCallEvent({
    required String endpoint,
    required String method, // GET, POST, PUT, DELETE
    int statusCode = 0,
    int responseTimeMs = 0,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'api_call_made',
        parameters: {
          'endpoint': endpoint,
          'method': method,
          'status_code': statusCode.toString(),
          'response_time_ms': responseTimeMs.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      print('DEBUG: Analytics event sent - api_call_made to $endpoint');
    } catch (e) {
      print('ERROR: Failed to log API call event: $e');
    }
  }
}
