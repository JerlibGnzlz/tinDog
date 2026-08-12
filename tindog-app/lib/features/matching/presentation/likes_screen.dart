import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/feedback/app_feedback.dart';
import '../../../core/network/session_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/tindog_loader.dart';
import '../data/discover_candidate.dart';
import '../data/matching_repository.dart';
import 'chats_providers.dart';
import 'likes_providers.dart';
import 'widgets/like_grid_card.dart';
import 'widgets/likes_boost_cta.dart';
import 'widgets/likes_empty_state.dart';
import 'widgets/likes_tabs_bar.dart';
import 'widgets/match_celebration_dialog.dart';
import '../../../core/feedback/app_haptics.dart';

class LikesScreen extends ConsumerStatefulWidget {
  const LikesScreen({super.key});

  @override
  ConsumerState<LikesScreen> createState() => _LikesScreenState();
}

class _LikesScreenState extends ConsumerState<LikesScreen> {
  LikesTabKind _tab = LikesTabKind.received;
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
          SizedBox(height: topInset + AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenH,
              AppSpacing.xs,
              AppSpacing.screenH,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Likes',
                  style: AppTypography.screenTitle.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Quienes te gustaron y a quiénes les diste like.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          LikesTabsBar(
            tab: _tab,
            receivedCount: receivedCount,
            onChanged: (tab) => setState(() => _tab = tab),
          ),
          const SizedBox(height: 10),
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
      case LikesTabKind.received:
        return _LikesGrid(
          provider: receivedLikesProvider,
          emptyTitle: 'Todavía no llegaron likes',
          emptySubtitle:
              'Cuando a alguien le guste tu mascota, aparece acá para que puedas responder.',
          enableLikeBack: true,
          likingPetId: _likingPetId,
          onLikeBack: _likeBack,
        );
      case LikesTabKind.sent:
        return _LikesGrid(
          provider: sentLikesProvider,
          emptyTitle: 'Todavía no enviaste likes',
          emptySubtitle:
              'En Desliza, deslizá a la derecha cuando veas un perrito que te encante.',
        );
      case LikesTabKind.topPicks:
        return LikesEmptyState(
          icon: Icons.auto_awesome_rounded,
          title: 'Top Picks',
          subtitle:
              'Selecciones destacadas para vos. Llega junto con Boost en el módulo de pagos.',
          primaryLabel: 'Ver Boost',
          onPrimary: () => showBoostPreviewSheet(context),
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
        AppHaptics.match();
        final goChat = await showMatchCelebrationDialog(
          context,
          petName: item.name,
          shortLocation: item.shortLocation,
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
        Future<void> refresh() async {
          ref.invalidate(provider);
          ref.invalidate(likesSummaryProvider);
          await ref.read(provider.future);
        }

        if (items.isEmpty) {
          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.card,
            onRefresh: refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.55,
                  child: LikesEmptyState(
                    title: emptyTitle,
                    subtitle: emptySubtitle,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.card,
          onRefresh: refresh,
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 84),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
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
                  if (enableLikeBack &&
                      onLikeBack != null &&
                      !item.matched) {
                    onLikeBack!(item);
                    return;
                  }
                  if (item.matched && item.matchId != null) {
                    context.push('/chats/${item.matchId}');
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
