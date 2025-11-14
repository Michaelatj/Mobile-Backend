// lib/pages/about_developer_page.dart
import 'package:flutter/material.dart';
import '../../core/widgets/app_bottom_nav.dart';

class AboutDeveloperPage extends StatelessWidget {
  const AboutDeveloperPage({super.key});

  @override
  Widget build(BuildContext context) {
    final members = const [
      _Member('Michael Andreas Tjendra', '231111210'),
      _Member('Silvani Chayadi', '231112945'),
      _Member('Diky Diwa Suwanto', '231110760'),
      _Member('Reno Kurniawan Panjaitan', '231112553'),
      _Member('Cindy Nathania', '231111567'),
    ];

    return AppBottomNavScaffold(
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            elevation: 0,
            backgroundColor: Theme.of(context).colorScheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primaryContainer,
                      Theme.of(context).colorScheme.secondaryContainer,
                    ],
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 42,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tentang Pengembang',
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.outlineVariant.withOpacity(0.6),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'BayangIn',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Aplikasi pencarian penyedia jasa yang ringkas dan ramah pengguna.',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Versi',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                              Text(
                                '1.0.0',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Daftar anggota tim
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: members.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _MemberTile(member: members[i]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Member {
  final String name;
  final String nim;
  const _Member(this.name, this.nim);
}

class _MemberTile extends StatelessWidget {
  final _Member member;
  const _MemberTile({required this.member});

  @override
  Widget build(BuildContext context) {
    String initials() {
      final parts = member.name.split(' ');
      if (parts.length == 1) {
        return parts.first.characters.take(2).toString().toUpperCase();
      }
      return (parts.first.characters.first + parts.last.characters.first)
          .toUpperCase();
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(child: Text(initials())),
        title: Text(member.name),
        subtitle: Text(member.nim),
      ),
    );
  }
}
