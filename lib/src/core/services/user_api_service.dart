import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user_role.dart';

/// Service untuk komunikasi dengan MockAPI User endpoint
/// Base URL: https://68f9c893ef8b2e621e7d69f4.mockapi.io/bantuin/api
///
/// Endpoint yang tersedia:
/// - GET /users — list semua users
/// - GET /users/{id} — get user by id
/// - POST /users — create user baru
/// - PUT /users/{id} — update user by id
/// - DELETE /users/{id} — delete user by id
class UserApiService {
  static const String _baseUrl =
      'https://68f9c893ef8b2e621e7d69f4.mockapi.io/bantuin/api';
  static const Duration _timeout = Duration(seconds: 30);

  /// Fetch semua users (admin/debug purposes)
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response =
          await http.get(Uri.parse('$_baseUrl/users')).timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception(
            'Failed to fetch users: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('DEBUG: UserApiService.getAllUsers() error: $e');
      rethrow;
    }
  }

  /// Fetch user by ID
  static Future<Map<String, dynamic>?> getUserById(String id) async {
    try {
      final response =
          await http.get(Uri.parse('$_baseUrl/users/$id')).timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception(
            'Failed to fetch user $id: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('DEBUG: UserApiService.getUserById() error: $e');
      rethrow;
    }
  }

  /// Fetch user by email (loop through all users and find match)
  /// Note: MockAPI doesn't support query filtering, so we fetch all and filter
  static Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      final allUsers = await getAllUsers();
      // Find user dengan email yang sesuai
      for (var user in allUsers) {
        if (user['email']?.toLowerCase() == email.toLowerCase()) {
          return user;
        }
      }
      return null;
    } catch (e) {
      print('DEBUG: UserApiService.getUserByEmail() error: $e');
      rethrow;
    }
  }

  /// Create user baru
  ///
  /// Body:
  /// {
  ///   "name": "John Doe",
  ///   "email": "john@example.com",
  ///   "role": "customer", // atau "provider"
  ///   "photoUrl": null,
  ///   "locationLabel": null,
  ///   "createdAt": "2025-01-13T12:00:00Z"
  /// }
  static Future<Map<String, dynamic>> createUser({
    required String name,
    required String email,
    required String role, // "customer" atau "provider"
    String? photoUrl,
    String? locationLabel,
    String? firebaseUid, // optional: store firebase UID in legacy API
  }) async {
    try {
      // Try to find existing user by email to avoid duplicate records.
      final existing = await getUserByEmail(email);
      final body = {
        'name': name,
        'email': email,
        'role': role, // "customer" atau "provider"
        'photoUrl': photoUrl,
        'locationLabel': locationLabel,
        'createdAt': DateTime.now().toIso8601String(),
        if (firebaseUid != null) 'firebaseUid': firebaseUid,
      };

      if (existing != null && existing['id'] != null) {
        // Update existing user (idempotent / upsert behavior)
        final id = existing['id'].toString();
        final response = await http
            .put(
              Uri.parse('$_baseUrl/users/$id'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body),
            )
            .timeout(_timeout);

        if (response.statusCode == 200) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        } else {
          throw Exception(
              'Failed to update existing user: ${response.statusCode} - ${response.body}');
        }
      }

      // No existing user — create new
      final response = await http
          .post(
            Uri.parse('$_baseUrl/users'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
            'Failed to create user: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('DEBUG: UserApiService.createUser() error: $e');
      rethrow;
    }
  }

  /// Update user profile
  static Future<Map<String, dynamic>> updateUser({
    required String id,
    required String name,
    String? photoUrl,
    String? locationLabel,
  }) async {
    try {
      // Send both legacy and new field names to maximize compatibility with
      // different API data shapes (some records use 'photo'/'location').
      final body = {
        'name': name,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (photoUrl != null) 'photo': photoUrl,
        if (locationLabel != null) 'locationLabel': locationLabel,
        if (locationLabel != null) 'location': locationLabel,
      };

      final response = await http
          .put(
            Uri.parse('$_baseUrl/users/$id'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
            'Failed to update user: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('DEBUG: UserApiService.updateUser() error: $e');
      rethrow;
    }
  }

  /// Delete user
  static Future<void> deleteUser(String id) async {
    try {
      final response =
          await http.delete(Uri.parse('$_baseUrl/users/$id')).timeout(_timeout);

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
            'Failed to delete user: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('DEBUG: UserApiService.deleteUser() error: $e');
      rethrow;
    }
  }

  /// Convert API user map to AppUser object
  static AppUser mapToAppUser(Map<String, dynamic> data) {
    final roleStr = (data['role'] as String?)?.toLowerCase() ?? 'customer';
    final role = roleStr == 'provider' ? UserRole.provider : UserRole.customer;

    return AppUser(
      id: data['id'] as String? ?? 'unknown',
      name: data['name'] as String? ?? 'Pengguna',
      role: role,
      photoUrl: data['photoUrl'] as String?,
      locationLabel: data['locationLabel'] as String?,
    );
  }
}

/// Represent AppUser dari API response
class AppUser {
  final String id;
  final String name;
  final UserRole role;
  final String? photoUrl;
  final String? locationLabel;

  AppUser({
    required this.id,
    required this.name,
    required this.role,
    this.photoUrl,
    this.locationLabel,
  });

  AppUser copyWith({
    String? id,
    String? name,
    UserRole? role,
    String? photoUrl,
    String? locationLabel,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      locationLabel: locationLabel ?? this.locationLabel,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role == UserRole.provider ? 'provider' : 'customer',
        'photoUrl': photoUrl,
        'locationLabel': locationLabel,
      };
}
