enum UserRole { customer, provider }

class AppUser {
  final String id;
  final String name;
  final UserRole role;
  final String? photoUrl;
  final String? locationLabel;

  const AppUser({
    required this.id,
    required this.name,
    required this.role,
    this.photoUrl,
    this.locationLabel,
  });

  AppUser copyWith({
    String? name,
    UserRole? role,
    String? photoUrl,
    String? locationLabel,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      locationLabel: locationLabel ?? this.locationLabel,
    );
  }
}
