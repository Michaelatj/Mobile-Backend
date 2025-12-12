// file: lib/src/core/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  // --- USER SECTION ---

  /// Simpan data user baru saat Sign Up
  static Future<void> saveUser({
    required String uid,
    required String email,
    required String name,
    required String role,
  }) async {
    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'photoUrl': '',
      'locationLabel': '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Ambil data user saat Sign In
  static Future<Map<String, dynamic>?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  /// Update profil user (Nama, Lokasi, Foto)
  static Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? locationLabel,
    String? photoUrl,
  }) async {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (locationLabel != null) data['locationLabel'] = locationLabel;
    if (photoUrl != null) data['photoUrl'] = photoUrl;

    await _db.collection('users').doc(uid).update(data);
  }

  // --- ORDERS / BOOKINGS SECTION ---

  /// Contoh fungsi untuk membuat pesanan baru (disimpan di koleksi 'orders')
  static Future<void> createOrder(Map<String, dynamic> orderData) async {
    // .add() akan membuat dokumen baru setiap kali dipanggil
    // ID-nya akan otomatis acak (misal: '8jKs9...', 'mN2kL...')
    await _db.collection('orders').add(orderData);
  }

  /// Ambil daftar pesanan milik user tertentu
  static Future<List<Map<String, dynamic>>> getUserOrders(String uid) async {
    try {
      final snapshot = await _db
          .collection('orders')
          .where('userId', isEqualTo: uid) // Filter berdasarkan User ID
          .orderBy('date', descending: true) // Urutkan dari yang terbaru
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Sertakan ID dokumen
        return data;
      }).toList();
    } catch (e) {
      print("Error fetching orders: $e");
      return [];
    }
  }
  static Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _db.collection('orders').doc(orderId).update({
      'status': newStatus,
    });
  }
}