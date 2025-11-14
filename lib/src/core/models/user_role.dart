enum UserRole { customer, provider }

class AppUser {
  final String id;
  final String name;
  final UserRole role;
  final String? photoUrl;
  final String? locationLabel;
  final int transactions; // Transaction count
  final List<String> orders; // Added orders array to store invoice codes

  const AppUser({
    required this.id,
    required this.name,
    required this.role,
    this.photoUrl,
    this.locationLabel,
    this.transactions = 0,
    this.orders = const [], // Initialize empty orders list
  });

  AppUser copyWith({
    String? name,
    UserRole? role,
    String? photoUrl,
    String? locationLabel,
    int? transactions,
    List<String>? orders, // Added orders to copyWith
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      locationLabel: locationLabel ?? this.locationLabel,
      transactions: transactions ?? this.transactions,
      orders: orders ?? this.orders, // Include orders in copyWith
    );
  }
}
