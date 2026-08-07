import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/feedback/app_feedback.dart';
import '../../../core/network/session_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/tindog_loader.dart';
import '../data/discover_candidate.dart';
import '../data/matching_repository.dart';
import 'chats_providers.dart';
import 'likes_providers.dart';
import 'widgets/like_grid_card.dart';
import 'widgets/likes_boost_cta.dart';
import 'widgets/match_celebration_dialog.dart';

enum _LikesTab { received, sent, topPicks }

class LikesScreen extends ConsumerStatefulWidget {
  const LikesScreen({super.key});

  @override
  ConsumerState<LikesScreen> createState() => _LikesScreenState();
}

class _LikesScreenState extends ConsumerState<LikesScreen> {
  _LikesTab _tab = _LikesTab.received;
  String? _likingPetId;

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(likesSummaryProvider);
    final receivedCount = summary.valueOrNull?.receivedCount ?? 0;
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: topInset + 8),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Text(
              'Likes',
              style: TextStyle(
                color: AppColors.textPrimary,
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
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: _buildBody()),
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 16,
                  child: Center(child: LikesBoostCta()),
                ),
              ],
            ),
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
          enableLikeBack: true,
          likingPetId: _likingPetId,
          onLikeBack: _likeBack,
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

  Future<void> _likeBack(LikeListItem item) async {
    if (_likingPetId != null) return;
    setState(() => _likingPetId = item.id);
    try {
      final result =
          await ref.read(matchingRepositoryProvider).like(item.id);
      if (!mounted) return;

      ref.invalidate(receivedLikesProvider);
      ref.invalidate(sentLikesProvider);
      ref.invalidate(likesSummaryProvider);
      ref.invalidate(matchesProvider);

      if (result.matched) {
        final goChat = await showMatchCelebrationDialog(
          context,
          petName: item.name,
        );
        if (!mounted) return;
        if (goChat && result.matchId != null) {
          context.push('/chats/${result.matchId}');
        } else {
          showTindogInfoSnackBar(context, '¡Match con ${item.name}!');
        }
      } else {
        showTindogInfoSnackBar(context, 'Like enviado a ${item.name}');
      }
    } catch (e) {
      if (!mounted) return;
      if (isSessionError(e)) {
        handleSessionExpired(ref, context, e);
        return;
      }
      showTindogErrorSnackBar(context, readableError(e));
    } finally {
      if (mounted) setState(() => _likingPetId = null);
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
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            _TabChip(
              label: receivedCount > 0 ? '$receivedCount Like' : 'Likes',
              selected: tab == _LikesTab.received,
              onTap: () => onChanged(_LikesTab.received),
            ),
            _TabChip(
              label: 'Enviados',
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
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Material(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.22)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? AppColors.primaryDark
                      : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ),
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
    this.enableLikeBack = false,
    this.likingPetId,
    this.onLikeBack,
  });

  final AutoDisposeFutureProvider<List<LikeListItem>> provider;
  final String emptyTitle;
  final String emptySubtitle;
  final bool enableLikeBack;
  final String? likingPetId;
  final Future<void> Function(LikeListItem item)? onLikeBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(provider);

    return async.when(
      loading: () => const Center(child: TindogLoader(message: 'Cargando…')),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                likesErrorMessage(error),
                style: TextStyle(color: Colors.red.shade700),
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
          color: AppColors.primary,
          backgroundColor: AppColors.card,
          onRefresh: () async {
            ref.invalidate(provider);
            ref.invalidate(likesSummaryProvider);
            await ref.read(provider.future);
          },
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 72),
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
                liking: likingPetId == item.id,
                onLikeBack: enableLikeBack && onLikeBack != null
                    ? () => onLikeBack!(item)
                    : null,
                onTap: () {
                  if (enableLikeBack && onLikeBack != null && !item.matched) {
                    onLikeBack!(item);
                    return;
                  }
                  showTindogInfoSnackBar(
                    context,
                    item.matched
                        ? '${item.name} — ya es match'
                        : 'Like enviado a ${item.name}',
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
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 88),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 56,
              color: AppColors.primary.withValues(alpha: 0.75),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.35,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () => context.go('/discover'),
              child: const Text('Ir a Desliza'),
            ),
          ],
        ),
      ),
    );
  }
}
