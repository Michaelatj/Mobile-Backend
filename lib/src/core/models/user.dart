import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class AppUser with _$AppUser {
  const factory AppUser({
    required String id,
    String? name,
    String? email,
    String? phoneNumber,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _AppUser;

  factory AppUser.fromJson(Map<String, dynamic> json) => _$AppUserFromJson(json);
  
  // Factory method to create AppUser from Firestore document
  factory AppUser.fromFirestore(Map<String, dynamic> data, String id) {
    return AppUser(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'],
      avatarUrl: data['avatarUrl'],
      createdAt: data['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['createdAt']) 
          : null,
      updatedAt: data['updatedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['updatedAt']) 
          : null,
    );
  }
}