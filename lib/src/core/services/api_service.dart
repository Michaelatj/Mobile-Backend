import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user_role.dart';

class ApiService {
  static const String _baseUrl = 'https://68f9d4baef8b2e621e7d95fb.mockapi.io';
  static const String _usersEndpoint = '/users';
  static const String _serviceProvidersEndpoint = '/serviceProviders';

  static Future<AppUser?> loginUser(String email, String password) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$_usersEndpoint'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> users = jsonDecode(response.body);
        
        // Find user by email and password
        for (var user in users) {
          if (user['email'] == email && user['password'] == password) {
            return AppUser(
              id: user['id'].toString(),
              name: user['name'] ?? 'User',
              role: (user['role'] ?? 'customer') == 'provider' 
                  ? UserRole.provider 
                  : UserRole.customer,
              photoUrl: user['photo'],
              locationLabel: user['location'],
              transactions: (user['transactions'] as List?)?.length ?? 0,
              orders: List<String>.from(user['orders'] as List? ?? []), // Get orders from API
            );
          }
        }
        return null; // User not found
      }
      return null;
    } catch (e) {
      print('[v0] Login error: $e');
      return null;
    }
  }

  static Future<bool> registerUser({
    required String email,
    required String password,
    required String name,
    required String role,
    String? location,
    String? photo,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$_usersEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
          'role': role,
          'location': location ?? 'Belum diatur',
          'photo': photo,
          'transactions': [], // Initialize as empty array
          'orders': [], // Initialize empty orders array
          'createdAt': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 201;
    } catch (e) {
      print('[v0] Register error: $e');
      return false;
    }
  }

  static Future<bool> processPayment({
    required String userId,
    required String invoiceCode,
    required Map<String, dynamic> orderData,
  }) async {
    try {
      // Get current user data
      final userResponse = await http.get(
        Uri.parse('$_baseUrl$_usersEndpoint/$userId'),
      ).timeout(const Duration(seconds: 10));

      if (userResponse.statusCode != 200) return false;

      final user = jsonDecode(userResponse.body);
      
      // Add new transaction
      final List<dynamic> transactions = user['transactions'] as List? ?? [];
      transactions.add({
        'id': invoiceCode,
        'date': DateTime.now().toIso8601String(),
        'amount': orderData['amount'],
        'paymentMethod': orderData['paymentMethod'],
      });

      // Add new order (invoice code)
      final List<dynamic> orders = user['orders'] as List? ?? [];
      orders.add(invoiceCode);

      // Update user with new transactions and orders
      final updateResponse = await http.put(
        Uri.parse('$_baseUrl$_usersEndpoint/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'transactions': transactions,
          'orders': orders,
        }),
      ).timeout(const Duration(seconds: 10));

      return updateResponse.statusCode == 200;
    } catch (e) {
      print('[v0] Process payment error: $e');
      return false;
    }
  }

  static Future<bool> updateUserTransactions(String userId, List<dynamic> transactions) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl$_usersEndpoint/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'transactions': transactions}),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print('[v0] Update transactions error: $e');
      return false;
    }
  }

  static Future<int> getUserTransactions(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$_usersEndpoint/$userId'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final user = jsonDecode(response.body);
        return (user['transactions'] as List?)?.length ?? 0;
      }
      return 0;
    } catch (e) {
      print('[v0] Get transactions error: $e');
      return 0;
    }
  }

  static Future<List<dynamic>> getServiceProviders() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$_serviceProvidersEndpoint'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print('[v0] Get service providers error: $e');
      return [];
    }
  }
}
