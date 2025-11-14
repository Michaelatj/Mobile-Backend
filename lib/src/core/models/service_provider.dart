class ServiceProvider {
  final String id;
  final String name;
  final String category;
  final double rating;
  final double distanceKm;
  final String description;
  final int priceFrom;

  ServiceProvider({
    required this.id,
    required this.name,
    required this.category,
    required this.rating,
    required this.distanceKm,
    required this.description,
    required this.priceFrom,
  });

  factory ServiceProvider.fromMap(Map<String, dynamic> map) {
    return ServiceProvider(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Unknown',
      category: map['category']?.toString() ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      distanceKm: (map['distanceKm'] as num?)?.toDouble() ?? 0.0,
      description: map['description']?.toString() ?? '',
      priceFrom: (map['priceFrom'] as num?)?.toInt() ?? 150000,
    );
  }

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