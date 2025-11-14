import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/state/providers.dart';
import '../../core/models/service_provider.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../providers/provider_detail_page.dart';
import 'package:intl/intl.dart'; // add intl to format currency
import '../../core/database/provider_dao.dart';

class HomePage extends ConsumerStatefulWidget {
  static const routePath = '/home';
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late final TextEditingController _searchController;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    final initial = ref.read(searchQueryProvider);
    _searchController = TextEditingController(text: initial);
    ref.listenManual<String?>(
      searchQueryProvider,
      (prev, next) {
        final value = next ?? '';
        if (_searchController.text != value) {
          _searchController.value = _searchController.value.copyWith(
            text: value,
            selection: TextSelection.collapsed(offset: value.length),
          );
        }
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(nearbyProvidersProvider);
  }

  Future<void> _showAddProviderDialog() async {
    final nameCtrl = TextEditingController();
    final catCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '100000');
    final distanceCtrl = TextEditingController(text: '1.0');
    final descCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tambah Penyedia'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama')),
              TextField(
                  controller: catCtrl,
                  decoration: const InputDecoration(labelText: 'Kategori')),
              TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Harga mulai (Rp)')),
              TextField(
                  controller: distanceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Jarak (km)')),
              TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Deskripsi')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Simpan')),
        ],
      ),
    );

    if (result == true) {
      final raw = int.tryParse(priceCtrl.text) ?? 100000;
      int rounded = ((raw / 1000).round()) * 1000;
      if (rounded < 1000) rounded = 1000;
      if (rounded != raw) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Harga disesuaikan menjadi Rp $rounded (kelipatan ribuan)')),
        );
      }

      final id = 'sp_${DateTime.now().millisecondsSinceEpoch}';
      final p = ServiceProvider(
        id: id,
        name: nameCtrl.text.trim().isEmpty
            ? 'Penyedia Baru'
            : nameCtrl.text.trim(),
        category: catCtrl.text.trim().isEmpty ? 'Umum' : catCtrl.text.trim(),
        rating: 0.0,
        distanceKm: double.tryParse(distanceCtrl.text) ?? 1.0,
        description:
            descCtrl.text.trim().isEmpty ? 'Deskripsi' : descCtrl.text.trim(),
        priceFrom: rounded,
      );
      await ProviderDao.insertProvider(p);
      await _refresh();
    }
  }

  Future<void> _showEditProviderDialog(ServiceProvider provider) async {
    final nameCtrl = TextEditingController(text: provider.name);
    final catCtrl = TextEditingController(text: provider.category);
    final priceCtrl =
        TextEditingController(text: provider.priceFrom.toString());
    final distanceCtrl =
        TextEditingController(text: provider.distanceKm.toString());
    final descCtrl = TextEditingController(text: provider.description);

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Penyedia'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama')),
              TextField(
                  controller: catCtrl,
                  decoration: const InputDecoration(labelText: 'Kategori')),
              TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Harga mulai (Rp)')),
              TextField(
                  controller: distanceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Jarak (km)')),
              TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Deskripsi')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Simpan')),
        ],
      ),
    );

    if (result == true) {
      final raw = int.tryParse(priceCtrl.text) ?? provider.priceFrom;
      int rounded = ((raw / 1000).round()) * 1000;
      if (rounded < 1000) rounded = 1000;
      if (rounded != raw) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Harga disesuaikan menjadi Rp $rounded (kelipatan ribuan)')),
        );
      }

      final updated = ServiceProvider(
        id: provider.id,
        name:
            nameCtrl.text.trim().isEmpty ? provider.name : nameCtrl.text.trim(),
        category: catCtrl.text.trim().isEmpty
            ? provider.category
            : catCtrl.text.trim(),
        rating: provider.rating,
        distanceKm: double.tryParse(distanceCtrl.text) ?? provider.distanceKm,
        description: descCtrl.text.trim().isEmpty
            ? provider.description
            : descCtrl.text.trim(),
        priceFrom: rounded,
      );
      await ProviderDao.updateProvider(updated);
      await _refresh();
    }
  }

  Future<void> _confirmDelete(ServiceProvider provider) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Penyedia'),
        content: Text(
            'Hapus ${provider.name}? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus')),
        ],
      ),
    );
    if (ok == true) {
      await ProviderDao.deleteProvider(provider.id);
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isList = ref.watch(listViewToggleProvider);
    final providersAsync = ref.watch(nearbyProvidersProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final selectedCategory = ref.watch(categoryFilterProvider);

    return AppBottomNavScaffold(
      child: SafeArea(
        child: Column(
          children: [
            // Header dengan gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primaryContainer,
                    Theme.of(context).colorScheme.secondaryContainer,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Halo, selamat datang 👋',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Cari penyedia jasa terbaik di sekitar Anda',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer
                                          .withOpacity(0.8),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        // Tombol Lokasi
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.my_location),
                            color: Theme.of(context).colorScheme.primary,
                            tooltip: 'Lokasiku Sekarang',
                            onPressed: () {
                              // TODO: Implementasi get current location
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Memperbarui lokasi...'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          hintText: 'Cari jasa atau kategori...',
                          hintStyle: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withOpacity(0.6),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (searchQuery.isNotEmpty)
                                IconButton(
                                  tooltip: 'Hapus',
                                  onPressed: () {
                                    ref
                                        .read(searchQueryProvider.notifier)
                                        .state = '';
                                    FocusScope.of(context).unfocus();
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                              IconButton(
                                tooltip: 'Filter',
                                onPressed: () {
                                  setState(() => _showFilters = !_showFilters);
                                },
                                icon: Icon(
                                  _showFilters
                                      ? Icons.filter_alt
                                      : Icons.filter_alt_outlined,
                                  color: _showFilters
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                ),
                              ),
                            ],
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        onChanged: (v) =>
                            ref.read(searchQueryProvider.notifier).state = v,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Filter Section (Expandable)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _showFilters ? null : 0,
              child: _showFilters
                  ? Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).colorScheme.surfaceContainerLow,
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context)
                                .colorScheme
                                .outlineVariant
                                .withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Filter & Sortir',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  ref.read(searchQueryProvider.notifier).state =
                                      '';
                                  ref
                                      .read(categoryFilterProvider.notifier)
                                      .state = null;
                                  FocusScope.of(context).unfocus();
                                },
                                icon:
                                    const Icon(Icons.refresh_rounded, size: 18),
                                label: const Text('Reset'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Kategori Filter
                          Text(
                            'Kategori',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilterChip(
                                label: const Text('Semua'),
                                selected: selectedCategory == null,
                                onSelected: (_) => ref
                                    .read(categoryFilterProvider.notifier)
                                    .state = null,
                                avatar: selectedCategory == null
                                    ? const Icon(Icons.check_circle, size: 18)
                                    : null,
                              ),
                              for (final c in const [
                                'Elektronik',
                                'Kebersihan',
                                'Perbaikan'
                              ])
                                FilterChip(
                                  label: Text(c),
                                  selected: selectedCategory == c,
                                  onSelected: (_) => ref
                                      .read(categoryFilterProvider.notifier)
                                      .state = c,
                                  avatar: selectedCategory == c
                                      ? const Icon(Icons.check_circle, size: 18)
                                      : null,
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Sortir Options
                          Text(
                            'Urutkan',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              ChoiceChip(
                                label: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.near_me, size: 16),
                                    SizedBox(width: 4),
                                    Text('Terdekat'),
                                  ],
                                ),
                                selected:
                                    true, // TODO: Connect to sort provider
                                onSelected: (_) {},
                              ),
                              ChoiceChip(
                                label: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star, size: 16),
                                    SizedBox(width: 4),
                                    Text('Rating Tertinggi'),
                                  ],
                                ),
                                selected: false,
                                onSelected: (_) {},
                              ),
                              ChoiceChip(
                                label: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.attach_money, size: 16),
                                    SizedBox(width: 4),
                                    Text('Termurah'),
                                  ],
                                ),
                                selected: false,
                                onSelected: (_) {},
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            // View Toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  providersAsync.when(
                    data: (list) => Text(
                      '${list.length} Penyedia Jasa',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    loading: () => Text(
                      'Memuat...',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    error: (_, __) => Text(
                      'Gagal memuat',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Spacer(),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment<bool>(
                        value: false,
                        icon: Icon(Icons.map_outlined, size: 18),
                      ),
                      ButtonSegment<bool>(
                        value: true,
                        icon: Icon(Icons.view_list_outlined, size: 18),
                      ),
                    ],
                    selected: {isList},
                    onSelectionChanged: (sel) => ref
                        .read(listViewToggleProvider.notifier)
                        .state = sel.first,
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      padding: const MaterialStatePropertyAll(
                        EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            OutlinedButton.icon(
              onPressed: _showAddProviderDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tambah'),
            ),
            // Content Area
            Expanded(
              child: providersAsync.when(
                data: (providers) => isList
                    ? _ListView(
                        providers: providers,
                        hasActiveFilters:
                            searchQuery.isNotEmpty || selectedCategory != null,
                        onClearFilters: () {
                          ref.read(searchQueryProvider.notifier).state = '';
                          ref.read(categoryFilterProvider.notifier).state =
                              null;
                          FocusScope.of(context).unfocus();
                        },
                        onRefresh: _refresh,
                        onEdit: _showEditProviderDialog,
                        onDelete: _confirmDelete,
                      )
                    : const _MapPlaceholder(),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Terjadi kesalahan: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListView extends StatelessWidget {
  final List<ServiceProvider> providers;
  final bool hasActiveFilters;
  final VoidCallback? onClearFilters;
  final Future<void> Function()? onRefresh;
  final void Function(ServiceProvider)? onEdit;
  final void Function(ServiceProvider)? onDelete;

  const _ListView({
    required this.providers,
    this.hasActiveFilters = false,
    this.onClearFilters,
    this.onRefresh,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (providers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Tidak ada hasil ditemukan',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Coba ubah kata kunci pencarian atau filter kategori yang Anda gunakan.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              if (hasActiveFilters) ...[
                const SizedBox(height: 20),
                FilledButton.tonalIcon(
                  onPressed: onClearFilters,
                  icon: const Icon(Icons.filter_alt_off_outlined),
                  label: const Text('Reset Semua Filter'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh ?? () async {},
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: providers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final p = providers[i];
          return _ProviderCard(
            provider: p,
            // pass handlers to card
            onEdit: onEdit,
            onDelete: onDelete,
          );
        },
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final ServiceProvider provider;
  final void Function(ServiceProvider)? onEdit;
  final void Function(ServiceProvider)? onDelete;

  const _ProviderCard({required this.provider, this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color:
                Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          // pass provider id to detail page route
          onTap: () =>
              context.go('${ProviderDetailPage.routeBase}/${provider.id}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Avatar with badge
                    Stack(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Theme.of(context).colorScheme.primaryContainer,
                                Theme.of(context)
                                    .colorScheme
                                    .secondaryContainer,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.home_repair_service_rounded,
                            size: 32,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                        // Verified Badge
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).colorScheme.surface,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.verified,
                              size: 16,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  provider.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') onEdit?.call(provider);
                                  if (value == 'delete')
                                    onDelete?.call(provider);
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                      value: 'edit', child: Text('Edit')),
                                  const PopupMenuItem(
                                      value: 'delete', child: Text('Hapus')),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondaryContainer
                                  .withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.category_rounded,
                                  size: 14,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSecondaryContainer,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  provider.category,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSecondaryContainer,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Rating Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 18,
                            color: Theme.of(context)
                                .colorScheme
                                .onTertiaryContainer,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            provider.rating.toStringAsFixed(1),
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onTertiaryContainer,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Distance Info
                Row(
                  children: [
                    Icon(
                      Icons.place_rounded,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${provider.distanceKm.toStringAsFixed(1)} km dari lokasi Anda',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                // Price & Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mulai dari',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Rp ${NumberFormat('#,###', 'id_ID').format(provider.priceFrom)}', // format price with thousands
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Chat Button
                        OutlinedButton(
                          onPressed: () {
                            // TODO: Navigate to chat
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child:
                              const Icon(Icons.chat_bubble_outline, size: 20),
                        ),
                        const SizedBox(width: 8),
                        // View Detail Button
                        FilledButton(
                          onPressed: () => context.go(
                              '${ProviderDetailPage.routeBase}/${provider.id}'), // pass provider id to detail page route
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Lihat Detail'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ));
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surfaceContainerLow,
            Theme.of(context).colorScheme.surfaceContainerHighest,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.map_rounded,
                  size: 64,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Tampilan Peta',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Integrasikan google_maps_flutter untuk melihat penyedia jasa di peta interaktif',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 20),
              FilledButton.tonalIcon(
                onPressed: () {
                  // TODO: Request location permission
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Meminta izin lokasi...'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.my_location),
                label: const Text('Aktifkan Lokasi'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
