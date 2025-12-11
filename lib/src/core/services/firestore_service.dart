import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/order.dart';

class FirestoreService {
  static const String _usersCollection = 'users';
  static const String _ordersCollection = 'orders';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user data from Firestore
  Stream<AppUser?> getUser(String userId) {
    return _firestore.collection(_usersCollection).doc(userId).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return AppUser.fromFirestore(snapshot.data()!, snapshot.id);
      } else {
        return null;
      }
    });
  }

  // Update user data in Firestore
  Future<void> updateUser(AppUser user) async {
    try {
      await _firestore.collection(_usersCollection).doc(user.id).set({
        'name': user.name,
        'email': user.email,
        'phoneNumber': user.phoneNumber,
        'avatarUrl': user.avatarUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating user: $e');
      rethrow;
    }
  }

  // Create user in Firestore if doesn't exist
  Future<void> createUser(AppUser user) async {
    try {
      await _firestore.collection(_usersCollection).doc(user.id).set({
        'name': user.name,
        'email': user.email,
        'phoneNumber': user.phoneNumber,
        'avatarUrl': user.avatarUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error creating user: $e');
      rethrow;
    }
  }

  // Get user's orders from Firestore
  Stream<List<Order>> getUserOrders(String userId) {
    return _firestore
        .collection(_ordersCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Order.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  // Add a new order to Firestore
  Future<String> addOrder(Order order) async {
    try {
      final docRef = await _firestore.collection(_ordersCollection).add({
        'userId': order.userId,
        'serviceId': order.serviceId,
        'serviceName': order.serviceName,
        'serviceProviderId': order.serviceProviderId,
        'serviceProviderName': order.serviceProviderName,
        'totalAmount': order.totalAmount,
        'status': _getStatusString(order.status),
        'notes': order.notes,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'scheduledAt': order.scheduledAt?.millisecondsSinceEpoch,
      });
      
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding order: $e');
      rethrow;
    }
  }

  // Update order status in Firestore
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      await _firestore.collection(_ordersCollection).doc(orderId).update({
        'status': _getStatusString(status),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating order status: $e');
      rethrow;
    }
  }

  // Get a specific order from Firestore
  Stream<Order?> getOrder(String orderId) {
    return _firestore.collection(_ordersCollection).doc(orderId).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return Order.fromFirestore(snapshot.data()!, snapshot.id);
      } else {
        return null;
      }
    });
  }

  // Helper method to convert enum to string
  String _getStatusString(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.confirmed:
        return 'confirmed';
      case OrderStatus.inProgress:
        return 'inProgress';
      case OrderStatus.completed:
        return 'completed';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }
}

// Singleton instance
final firestoreService = FirestoreService();