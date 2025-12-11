import 'package:freezed_annotation/freezed_annotation.dart';

part 'order.freezed.dart';
part 'order.g.dart';

enum OrderStatus { pending, confirmed, inProgress, completed, cancelled }

@freezed
class Order with _$Order {
  const factory Order({
    required String id,
    required String userId,
    String? serviceId,
    String? serviceName,
    String? serviceProviderId,
    String? serviceProviderName,
    required double totalAmount,
    required OrderStatus status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? scheduledAt,
  }) = _Order;

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
  
  // Factory method to create Order from Firestore document
  factory Order.fromFirestore(Map<String, dynamic> data, String id) {
    return Order(
      id: id,
      userId: data['userId'] ?? '',
      serviceId: data['serviceId'],
      serviceName: data['serviceName'],
      serviceProviderId: data['serviceProviderId'],
      serviceProviderName: data['serviceProviderName'],
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: _getStatusFromString(data['status'] ?? 'pending'),
      notes: data['notes'],
      createdAt: data['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['createdAt']) 
          : null,
      updatedAt: data['updatedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['updatedAt']) 
          : null,
      scheduledAt: data['scheduledAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['scheduledAt']) 
          : null,
    );
  }

  static OrderStatus _getStatusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'inprogress':
        return OrderStatus.inProgress;
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }
}