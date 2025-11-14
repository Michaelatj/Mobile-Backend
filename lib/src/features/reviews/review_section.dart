import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/repository/review_repository.dart';
import '../../core/database/review_dao.dart';
import '../../core/models/review.dart';
import '../../core/database/provider_dao.dart';
import '../../core/state/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReviewSection extends ConsumerStatefulWidget {
  final String providerId;
  final String? userId; // bisa null kalau belum login

  const ReviewSection({
    super.key,
    required this.providerId,
    this.userId,
  });

  @override
  ConsumerState<ReviewSection> createState() => _ReviewSectionState();
}

class _ReviewSectionState extends ConsumerState<ReviewSection> {
  late Future<List<Review>> _futureReviews;

  @override
  void initState() {
    super.initState();
    _futureReviews = _loadReviews();
  }

  Future<List<Review>> _loadReviews() {
    final pid = widget.providerId;
    // remote-first, jika error fallback ke local DB
    return ReviewRepository.fetchReviews(pid);
    // .catchError((_) => ReviewDao.getReviewsByProvider(pid));
  }

  Future<void> _syncRating() async {
  final reviews = await ReviewRepository.fetchReviews(widget.providerId);
  final avg = reviews.isEmpty
      ? 0.0
      : reviews.map((r) => r.stars).reduce((a, b) => a + b) / reviews.length;
  final rounded = double.parse(avg.toStringAsFixed(1));

  await ProviderDao.updateProviderRating(widget.providerId, rounded); // SEKARANG ADA!

  ref.invalidate(providerByIdProvider(widget.providerId));
  ref.invalidate(nearbyProvidersProvider);
}

  Future<void> _openForm({Review? initial}) async {
    final result = await showDialog<Review>(
      context: context,
      builder: (_) => _ReviewDialog(
        providerId: widget.providerId,
        userId: widget.userId ?? 'guest',
        initialReview: initial,
      ),
    );
    if (result != null) {
      await _syncRating();
      setState(() => _futureReviews = _loadReviews());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  initial == null ? 'Ulasan terkirim' : 'Ulasan diperbarui')),
        );
      }
    }
  }

  Future<void> _confirmDelete(Review r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Ulasan'),
        content: const Text('Yakin ingin menghapus ulasan ini?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(_, false),
              child: const Text('Batal')),
          FilledButton(
              onPressed: () => Navigator.pop(_, true),
              child: const Text('Hapus')),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ReviewDao.deleteReview(r.id);
        await _syncRating();
        setState(() => _futureReviews = _loadReviews());
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Ulasan dihapus')));
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Gagal hapus: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Review>>(
      future: _futureReviews,
      builder: (context, snap) {
        final reviews = snap.data ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top header: rating card + action
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Rating big card (left)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          // compute avg for immediate view if available
                          reviews.isEmpty
                              ? '0.0'
                              : (reviews
                                          .map((r) => r.stars)
                                          .reduce((a, b) => a + b) /
                                      reviews.length)
                                  .toStringAsFixed(1),
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rating pengguna',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              // show stars visualization (rounded)
                              Icon(Icons.star, color: Colors.amber, size: 16),
                              const SizedBox(width: 6),
                              Text('${reviews.length} ulasan',
                                  style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  icon: const Icon(Icons.rate_review_outlined),
                  label: const Text('Review'),
                  onPressed: () => _openForm(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Body: loading / empty / list
            if (snap.connectionState == ConnectionState.waiting)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (snap.hasError)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('Gagal memuat ulasan: ${snap.error}'),
              )
            else if (reviews.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Belum ada ulasan'),
              )
            else
              // List of styled review tiles
              Column(
                children: reviews.map((r) {
                  final isOwner =
                      widget.userId != null && widget.userId == r.userId;
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8)
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      leading: CircleAvatar(
                        radius: 20,
                        child: Text(
                          r.userId.isNotEmpty ? r.userId[0].toUpperCase() : 'U',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                              child: Text(
                            r.userId,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          )),
                          Row(
                            children: List.generate(
                                5,
                                (i) => Icon(Icons.star,
                                    size: 14,
                                    color: i < r.stars
                                        ? Colors.amber
                                        : Colors.grey.shade600)),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Text(r.comment),
                          const SizedBox(height: 8),
                          Text(
                            DateFormat.yMMMd()
                                .add_Hm()
                                .format(r.createdAt.toLocal()),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      trailing: isOwner
                          ? PopupMenuButton<String>(
                              onSelected: (v) {
                                if (v == 'edit') _openForm(initial: r);
                                if (v == 'delete') _confirmDelete(r);
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                    value: 'edit', child: Text('Edit')),
                                PopupMenuItem(
                                    value: 'delete', child: Text('Hapus')),
                              ],
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
          ],
        );
      },
    );
  }
}

/* Dialog widget for add/edit review */
class _ReviewDialog extends StatefulWidget {
  final String providerId;
  final String userId;
  final Review? initialReview;
  const _ReviewDialog({
    required this.providerId,
    required this.userId,
    this.initialReview,
  });

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  late int _stars;
  late TextEditingController _ctrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _stars = widget.initialReview?.stars ?? 5;
    _ctrl = TextEditingController(text: widget.initialReview?.comment ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final comment = _ctrl.text.trim();
    if (comment.isEmpty) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Komentar tidak boleh kosong')));
      return;
    }
    setState(() => _saving = true);
    try {
      final review = Review(
        id: widget.initialReview?.id ??
            'rv_${DateTime.now().millisecondsSinceEpoch}',
        providerId: widget.providerId,
        userId: widget.userId,
        stars: _stars,
        comment: comment,
        createdAt: DateTime.now(),
      );
      if (widget.initialReview == null) {
        // saat submit ulasan
        await ReviewRepository.postReview(review);
      } else {
        await ReviewDao.updateReview(review);
      }
      if (mounted) Navigator.pop(context, review);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menyimpan ulasan: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title:
          Text(widget.initialReview == null ? 'Tulis Ulasan' : 'Edit Ulasan'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<int>(
            value: _stars,
            items: [1, 2, 3, 4, 5]
                .map((s) =>
                    DropdownMenuItem(value: s, child: Text('$s Bintang')))
                .toList(),
            onChanged: (v) => setState(() => _stars = v ?? 5),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _ctrl,
            decoration: const InputDecoration(labelText: 'Komentar'),
            maxLines: 4,
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal')),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(widget.initialReview == null ? 'Kirim' : 'Update'),
        ),
      ],
    );
  }
}
