import 'dart:math';

import '../models/service_provider.dart';
import '../models/review.dart';

class DummyData {
  static final _rnd = Random(2025);

  static Future<List<ServiceProvider>> seedProviders() async {
    const categories = [
      'Elektronik',
      'Kebersihan',
      'Perbaikan',
      'Transportasi',
      'Perawatan'
    ];
    const names = [
      'Ahmad Elektronik',
      'Siti Cleaning',
      'Budi Tukang',
      'Rina Babysitter',
      'Joko Listrik',
      'Dewi Laundry',
      'Tono Montir',
      'Lina Nanny',
      'Eko Service AC',
      'Nina Makeup',
      'Yudi Panggilan',
      'Wati Bersih',
      'Fajar Tukang',
      'Anisa Elektrik',
      'Rio Teknisi',
      'Tari Home Care',
      'Gilang Painter',
      'Maya Organizer',
      'Rizky Driver',
      'Salsa Cat Ulang',
    ];

    final providers = <ServiceProvider>[];
    for (var i = 0; i < 20; i++) {
      final cat = categories[_rnd.nextInt(categories.length)];
      final rating = (40 + _rnd.nextInt(20)) / 10.0; // 4.0 .. 5.9 (cap later)
      // Generate price starting from 50000, in steps of 5000, up to 300000
      final price =
          50000 + (_rnd.nextInt(50) * 5000); // 50000, 55000, ..., 300000
      providers.add(
        ServiceProvider(
          id: 'sp_${i + 1}',
          name: names[i],
          category: cat,
          rating: double.parse(rating.clamp(1.0, 5.0).toStringAsFixed(1)),
          distanceKm: double.parse((_rnd.nextDouble() * 5).toStringAsFixed(1)),
          description:
              'Jasa $cat profesional dan terpercaya dengan pelayanan ramah.',
          priceFrom: price,
        ),
      );
    }
    return providers;
  }

  static Future<List<Review>> seedReviews(
      List<ServiceProvider> providers) async {
    const comments = [
      'Sangat memuaskan! Pekerjaan rapi.',
      'Datang tepat waktu dan ramah.',
      'Harga terjangkau, rekomendasi!',
      'Sedikit terlambat namun hasil bagus.',
      'Layanan cepat dan berkualitas.',
    ];

    final reviews = <Review>[];
    var reviewId = 1;
    for (final p in providers) {
      final count = 3 + _rnd.nextInt(4); // 3..6 reviews per provider
      for (var i = 0; i < count; i++) {
        reviews.add(
          Review(
            id: 'rv_${reviewId++}',
            providerId: p.id,
            userId: 'user_${_rnd.nextInt(1000)}', // Dummy userId
            stars: 3 + _rnd.nextInt(3), // 3..5
            comment: comments[_rnd.nextInt(comments.length)],
            createdAt:
                DateTime.now().subtract(Duration(days: _rnd.nextInt(30))),
          ),
        );
      }
    }
    return reviews;
  }
}
