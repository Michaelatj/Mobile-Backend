import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/service_provider.dart';

class ProviderDao {
  static const String baseUrl = 'https://68f9d4baef8b2e621e7d95fb.mockapi.io';
  static const String resource = 'serviceProviders'; // DARI MOCKAPI

  // === GET ===
  static Future<ServiceProvider?> getProviderById(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$resource/$id'));
      if (response.statusCode == 200) {
        return ServiceProvider.fromMap(json.decode(response.body));
      }
    } catch (e) {
      print('Error getProviderById($id): $e');
    }
    return null;
  }

  static Future<List<ServiceProvider>> getAllProviders() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$resource'));
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((e) => ServiceProvider.fromMap(e)).toList();
      }
    } catch (e) {
      print('Error getAllProviders: $e');
    }
    return [];
  }

  // === INSERT ===
  static Future<ServiceProvider?> insertProvider(ServiceProvider p) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$resource'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(p.toMap()),
      );
      if (response.statusCode == 201) {
        return ServiceProvider.fromMap(json.decode(response.body));
      }
    } catch (e) {
      print('Error insertProvider: $e');
    }
    return null;
  }

  // === UPDATE FULL PROVIDER ===
  static Future<ServiceProvider?> updateProvider(ServiceProvider p) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/$resource/${p.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(p.toMap()),
      );
      if (response.statusCode == 200) {
        return ServiceProvider.fromMap(json.decode(response.body));
      }
    } catch (e) {
      print('Error updateProvider: $e');
    }
    return null;
  }

  // === UPDATE RATING ONLY ===
  static Future<void> updateProviderRating(String id, double rating) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/$resource/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'rating': rating}),
      );
      if (response.statusCode != 200) {
        print('Failed update rating: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updateProviderRating: $e');
    }
  }

  // === DELETE ===
  static Future<bool> deleteProvider(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/$resource/$id'));
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleteProvider: $e');
      return false;
    }
  }
}