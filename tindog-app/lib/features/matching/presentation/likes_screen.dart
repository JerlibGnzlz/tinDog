import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/feedback/app_feedback.dart';
import '../../../shared/widgets/tindog_loader.dart';
import '../data/discover_candidate.dart';
import 'likes_providers.dart';
import 'matching_nav.dart';
import 'widgets/discover_bottom_nav.dart';
import 'widgets/like_grid_card.dart';

enum _LikesTab { received, sent, topPicks }

class LikesScreen extends ConsumerStatefulWidget {
  const LikesScreen({super.key});

  @override
  ConsumerState<LikesScreen> createState() => _LikesScreenState();
}

class _LikesScreenState extends ConsumerState<LikesScreen> {
  _LikesTab _tab = _LikesTab.sent;

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(likesSummaryProvider);
    final receivedCount = summary.valueOrNull?.receivedCount ?? 0;
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: topInset + 8),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Text(
              'Likes',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _LikesTabs(
            tab: _tab,
            receivedCount: receivedCount,
            onChanged: (tab) => setState(() => _tab = tab),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildBody()),
          DiscoverBottomNav(
            active: DiscoverNavTab.likes,
            likesBadge: receivedCount > 0 ? receivedCount : null,
            chatsBadge: false,
            onSelected: (tab) => handleMatchingBottomNav(context, tab),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_tab) {
      case _LikesTab.received:
        return _LikesGrid(
          provider: receivedLikesProvider,
          emptyTitle: 'Todavía no tenés likes',
          emptySubtitle: 'Cuando alguien te dé like, aparece acá.',
        );
      case _LikesTab.sent:
        return _LikesGrid(
          provider: sentLikesProvider,
          emptyTitle: 'Sin likes enviados',
          emptySubtitle: 'Deslizá a la derecha en Desliza para empezar.',
        );
      case _LikesTab.topPicks:
        return const _EmptyLikesState(
          title: 'Top Picks',
          subtitle: 'Próximamente en tinDog.',
        );
    }
  }
}

class _LikesTabs extends StatelessWidget {
  const _LikesTabs({
    required this.tab,
    required this.receivedCount,
    required this.onChanged,
  });

  final _LikesTab tab;
  final int receivedCount;
  final ValueChanged<_LikesTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _TabChip(
            label: receivedCount > 0 ? '$receivedCount Like' : 'Likes',
            selected: tab == _LikesTab.received,
            onTap: () => onChanged(_LikesTab.received),
          ),
          _TabChip(
            label: 'Likes enviados',
            selected: tab == _LikesTab.sent,
            onTap: () => onChanged(_LikesTab.sent),
          ),
          _TabChip(
            label: 'Top Picks',
            selected: tab == _LikesTab.topPicks,
            onTap: () => onChanged(_LikesTab.topPicks),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF9A9A9A),
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 2.5,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: selected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LikesGrid extends ConsumerWidget {
  const _LikesGrid({
    required this.provider,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  final AutoDisposeFutureProvider<List<LikeListItem>> provider;
  final String emptyTitle;
  final String emptySubtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(provider);

    return async.when(
      loading: () => const Center(
        child: TindogLoader(message: 'Cargando…', inverted: true),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                likesErrorMessage(error),
                style: TextStyle(color: Colors.red.shade300),
                textAlign: TextAlign.center,
              ),
              TextButton(
                onPressed: () => ref.invalidate(provider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return _EmptyLikesState(
            title: emptyTitle,
            subtitle: emptySubtitle,
          );
        }

        return RefreshIndicator(
          color: Colors.white,
          backgroundColor: const Color(0xFF2A2A2A),
          onRefresh: () async {
            ref.invalidate(provider);
            ref.invalidate(likesSummaryProvider);
            await ref.read(provider.future);
          },
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.72,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return LikeGridCard(
                item: item,
                onTap: () {
                  showTindogInfoSnackBar(
                    context,
                    item.matched
                        ? '${item.name} — ya es match'
                        : '${item.name} — detalle próximamente',
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _EmptyLikesState extends StatelessWidget {
  const _EmptyLikesState({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite_border, size: 56, color: Colors.white38),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/discover'),
              child: const Text('Ir a Desliza'),
            ),
          ],
        ),
      ),
    );
  }
}
