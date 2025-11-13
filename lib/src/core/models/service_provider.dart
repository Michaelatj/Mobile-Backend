class ServiceProvider {
  final String id;
  final String name;
  final String category;
  final double rating;
  final double distanceKm;
  final String description;
  final int priceFrom; // in local currency minor units? kept as int

  ServiceProvider({
    required this.id,
    required this.name,
    required this.category,
    required this.rating,
    required this.distanceKm,
    required this.description,
    required this.priceFrom,
  });

  factory ServiceProvider.fromMap(Map<String, dynamic> map) => ServiceProvider(
        id: map['id'],
        name: map['name'],
        category: map['category'],
        rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
        distanceKm: (map['distanceKm'] as num?)?.toDouble() ?? 0.0,
        description: map['description'],
        priceFrom: map['priceFrom'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'category': category,
        'rating': rating,
        'distanceKm': distanceKm,
        'description': description,
        'priceFrom': priceFrom,
      };
}
