import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';
import '../services/firestore_service.dart';

// AsyncNotifier untuk mengelola daftar order user
class UserOrdersNotifier extends FamilyAsyncNotifier<List<Order>, String> {
  @override
  Future<List<Order>> build(String userId) async {
    // Load initial orders
    final ordersStream = firestoreService.getUserOrders(userId);
    return ordersStream.first;
  }

  Future<void> addOrder(Order order) async {
    final previousState = state;
    
    try {
      final orderId = await firestoreService.addOrder(order);
      // Refresh the list
      final updatedOrders = await firestoreService.getUserOrders(order.userId).first;
      state = AsyncData(updatedOrders);
    } catch (error) {
      state = AsyncError(error, StackTrace.current);
      // Kembalikan ke state sebelumnya jika gagal
      state = previousState;
    }
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    final previousState = state;
    
    try {
      // First get the order to extract userId
      final orderSnapshot = await firestoreService.getOrder(orderId).first;
      if (orderSnapshot != null) {
        await firestoreService.updateOrderStatus(orderId, status);
        // Refresh the list
        final updatedOrders = await firestoreService.getUserOrders(orderSnapshot.userId).first;
        state = AsyncData(updatedOrders);
      }
    } catch (error) {
      state = AsyncError(error, StackTrace.current);
      // Kembalikan ke state sebelumnya jika gagal
      state = previousState;
    }
  }
}

// Provider untuk daftar order user
final userOrdersProvider = 
    AsyncNotifierProvider.family<UserOrdersNotifier, List<Order>, String>((ref, userId) {
  return UserOrdersNotifier()..ref = ref;
});

// Provider untuk menambah order
final addOrderProvider = 
    NotifierProvider<AddOrderNotifier, void>(AddOrderNotifier);

class AddOrderNotifier extends Notifier<void> {
  @override
  void build() {}
  
  Future<void> addOrder(Order order) async {
    final userId = order.userId;
    final userOrdersProviderForUserId = userOrdersProvider(userId);
    
    final previousState = ref.read(userOrdersProviderForUserId);
    ref.read(userOrdersProviderForUserId.notifier).state = const AsyncLoading();

    try {
      final orderId = await firestoreService.addOrder(order);
      // Refresh the list
      final updatedOrders = await firestoreService.getUserOrders(userId).first;
      ref.read(userOrdersProviderForUserId.notifier).state = AsyncData(updatedOrders);
    } catch (error) {
      // Kembalikan ke state sebelumnya jika gagal
      ref.read(userOrdersProviderForUserId.notifier).state = previousState;
      rethrow;
    }
  }
}

// AsyncNotifier untuk order tunggal
class OrderNotifier extends FamilyAsyncNotifier<Order?, String> {
  @override
  Future<Order?> build(String orderId) async {
    final orderStream = firestoreService.getOrder(orderId);
    return orderStream.first;
  }

  Future<void> updateStatus(String orderId, OrderStatus status) async {
    final previousState = state;
    state = const AsyncLoading();

    try {
      await firestoreService.updateOrderStatus(orderId, status);
      // Refresh the order
      final updatedOrder = await firestoreService.getOrder(orderId).first;
      state = AsyncData(updatedOrder);
    } catch (error) {
      state = AsyncError(error, StackTrace.current);
      // Kembalikan ke state sebelumnya jika gagal
      state = previousState;
    }
  }
}

// Provider untuk order tunggal
final orderProvider = 
    AsyncNotifierProvider.family<OrderNotifier, Order?, String>((ref, orderId) {
  return OrderNotifier()..ref = ref;
});