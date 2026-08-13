import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/feedback/app_feedback.dart';
import '../../../core/feedback/app_haptics.dart';
import '../../../core/network/session_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/pet_photo_viewer_screen.dart';
import '../../../shared/widgets/pet_video_player_screen.dart';
import '../../../shared/widgets/tindog_empty_state.dart';
import '../../../shared/models/swipe_preview_media.dart';
import '../../chat/presentation/widgets/match_profile_sheet.dart';
import '../../profile/presentation/profile_providers.dart';
import '../../safety/presentation/safety_sheets.dart';
import 'discover_filters.dart';
import 'discover_providers.dart';
import 'widgets/discover_actions.dart';
import 'widgets/discover_card.dart';
import 'widgets/discover_card_skeleton.dart';
import 'widgets/discover_filters_sheet.dart';
import 'widgets/match_celebration_dialog.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final _cardController = DiscoverCardController();

  Future<void> _onDecision(DiscoverSwipeDecision decision) async {
    final current = ref.read(discoverDeckProvider).current;
    final name = current?.name ?? 'mascota';
    try {
      await ref.read(discoverDeckProvider.notifier).decide(decision);
      if (!mounted) return;
      final deck = ref.read(discoverDeckProvider);
      if (decision == DiscoverSwipeDecision.like && deck.lastMatched) {
        AppHaptics.match();
        final goChat = await showMatchCelebrationDialog(
          context,
          petName: name,
          shortLocation: current?.shortLocation,
        );
        if (!mounted) return;
        if (goChat && deck.lastMatchId != null) {
          context.push('/chats/${deck.lastMatchId}');
        }
      }
    } catch (e) {
      if (!mounted) return;
      if (isSessionError(e)) {
        handleSessionExpired(ref, context, e);
        return;
      }
      showTindogErrorSnackBar(context, readableError(e));
    }
  }

  Future<void> _onRewind() async {
    final deck = ref.read(discoverDeckProvider);
    if (!deck.canRewind) {
      showTindogInfoSnackBar(context, 'No hay nada para deshacer');
      return;
    }
    try {
      await ref.read(discoverDeckProvider.notifier).rewind();
      AppHaptics.rewind();
    } catch (e) {
      if (!mounted) return;
      if (isSessionError(e)) {
        handleSessionExpired(ref, context, e);
        return;
      }
      showTindogErrorSnackBar(context, readableError(e));
    }
  }

  Future<void> _openFilters() async {
    final current = ref.read(discoverFiltersProvider);
    final next = await showDiscoverFiltersSheet(
      context: context,
      current: current,
    );
    if (next == null || !mounted) return;
    ref.read(discoverFiltersProvider.notifier).state = next;
  }

  Future<void> _onEmptyPrimary(DiscoverEmptyPrimary action) async {
    switch (action) {
      case DiscoverEmptyPrimary.reload:
        ref.read(discoverDeckProvider.notifier).reload();
      case DiscoverEmptyPrimary.openLocation:
        context.push('/profile/location');
      case DiscoverEmptyPrimary.openFilters:
        await _openFilters();
      case DiscoverEmptyPrimary.openVideos:
        context.push('/profile/videos');
      case DiscoverEmptyPrimary.clearFilters:
        final mode = ref.read(discoverFiltersProvider).mode;
        ref.read(discoverFiltersProvider.notifier).state =
            DiscoverFilters(mode: mode);
        if (mounted) {
          showTindogInfoSnackBar(context, 'Filtros limpios');
        }
    }
  }

  Future<void> _onEmptySecondary(DiscoverEmptySecondary action) async {
    switch (action) {
      case DiscoverEmptySecondary.forYou:
        ref.read(discoverFiltersProvider.notifier).state =
            const DiscoverFilters();
      case DiscoverEmptySecondary.openFilters:
        await _openFilters();
      case DiscoverEmptySecondary.openProfile:
        context.push('/profile');
    }
  }

  void _onModeSelected(DiscoverMode mode) {
    final current = ref.read(discoverFiltersProvider);
    final hadExtras = current.hasExtraFilters;
    final next = current.forModeChange(mode);
    ref.read(discoverFiltersProvider.notifier).state = next;
    if (mode == DiscoverMode.forYou && hadExtras && mounted) {
      showTindogInfoSnackBar(context, 'Para ti sin filtros extra');
    }
  }

  void _clearExtraFilters() {
    final current = ref.read(discoverFiltersProvider);
    ref.read(discoverFiltersProvider.notifier).state = current.withoutExtras();
    showTindogInfoSnackBar(context, 'Filtros limpios');
  }

  @override
  Widget build(BuildContext context) {
    final deck = ref.watch(discoverDeckProvider);
    final filters = ref.watch(discoverFiltersProvider);
    final profile = ref.watch(myProfileProvider).valueOrNull;
    final pet = ref.watch(myPetProvider).valueOrNull;
    final current = deck.current;
    final topInset = MediaQuery.paddingOf(context).top;
    final hasGps = profile?.hasGps ?? false;
    final hasOwnBreed = (pet?.breed ?? '').trim().isNotEmpty;
    final emptySpec = filters.emptySpec(
      hasGps: hasGps,
      hasOwnBreed: hasOwnBreed,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (deck.isLoading && current == null)
                  DiscoverCardSkeleton(topInset: topInset)
                else if (deck.errorMessage != null && current == null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            deck.errorMessage!,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => ref
                                .read(discoverDeckProvider.notifier)
                                .reload(),
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (current != null)
                  DiscoverCard(
                    key: ValueKey('${filters.mode.apiValue}-${current.id}'),
                    candidate: current,
                    controller: _cardController,
                    storyTopInset: topInset + 52,
                    onDecision: _onDecision,
                    onOpenGallery: (mediaIndex) {
                      final items = current.mediaItems;
                      if (items.isEmpty) return;
                      final i = mediaIndex.clamp(0, items.length - 1);
                      final item = items[i];
                      if (item.isVideo) {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => PetVideoPlayerScreen(
                              url: item.url,
                              title: item.durationSec != null
                                  ? formatMediaDuration(item.durationSec!)
                                  : current.name,
                            ),
                          ),
                        );
                        return;
                      }
                      final photoUrls = current.photoUrls;
                      if (photoUrls.isEmpty) return;
                      final photoIndex = photoUrls.indexOf(item.url);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PetPhotoViewerScreen(
                            urls: photoUrls,
                            initialIndex: photoIndex >= 0 ? photoIndex : 0,
                            title: current.name,
                          ),
                        ),
                      );
                    },
                    onOwnerTap: () => showMatchProfileSheet(
                      context: context,
                      pet: current,
                      onSafety: current.ownerUserId == null
                          ? null
                          : () {
                              showSafetyActionsSheet(
                                context: context,
                                ref: ref,
                                otherUserId: current.ownerUserId!,
                                otherName:
                                    current.ownerName?.trim().isNotEmpty == true
                                        ? current.ownerName!.trim()
                                        : current.name,
                              );
                            },
                    ),
                    bottomBar: DiscoverActions(
                      onPass: _cardController.pass,
                      onLike: _cardController.like,
                      canRewind: deck.canRewind,
                      onRewind: _onRewind,
                      onSuperLike: () => showTindogInfoSnackBar(
                        context,
                        'Super like — próximamente',
                      ),
                      onBoost: () => showTindogInfoSnackBar(
                        context,
                        'Boost — próximamente',
                      ),
                    ),
                  )
                else
                  _EmptyDiscover(
                    spec: emptySpec,
                    onRefresh: () =>
                        ref.read(discoverDeckProvider.notifier).reload(),
                    onPrimary: () => _onEmptyPrimary(emptySpec.primaryAction),
                    onSecondary: emptySpec.secondaryAction == null
                        ? null
                        : () => _onEmptySecondary(emptySpec.secondaryAction!),
                    onRewind: deck.canRewind ? _onRewind : null,
                  ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.only(top: topInset),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.surface,
                          Color(0xE6F9F1E1), // ~90%
                          Color(0x99F9F1E1), // ~60%
                          Color(0x00F9F1E1),
                        ],
                        stops: [0, 0.35, 0.7, 1],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _DiscoverTopBar(
                          mode: filters.mode,
                          filtersActive: filters.hasExtraFilters,
                          onModeSelected: _onModeSelected,
                          onOpenFilters: _openFilters,
                        ),
                        if (filters.hasExtraFilters)
                          _ActiveFiltersBar(
                            summary: filters.activeSummary,
                            onClear: _clearExtraFilters,
                            onEdit: _openFilters,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDiscover extends StatelessWidget {
  const _EmptyDiscover({
    required this.spec,
    required this.onRefresh,
    required this.onPrimary,
    this.onSecondary,
    this.onRewind,
  });

  final DiscoverEmptySpec spec;
  final Future<void> Function() onRefresh;
  final VoidCallback onPrimary;
  final VoidCallback? onSecondary;
  final VoidCallback? onRewind;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.card,
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxxl,
              AppSpacing.xxxl + 72,
              AppSpacing.xxxl,
              AppSpacing.xxxl,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TindogEmptyState(
                    title: spec.title,
                    subtitle: spec.subtitle,
                    icon: spec.icon,
                    primaryLabel: spec.primaryLabel,
                    onPrimary: onPrimary,
                    secondaryLabel: spec.secondaryLabel,
                    onSecondary: onSecondary,
                    padding: EdgeInsets.zero,
                  ),
                  if (onRewind != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    TextButton.icon(
                      onPressed: onRewind,
                      icon: const Icon(Icons.replay_rounded),
                      label: const Text('Deshacer último swipe'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFD4A017),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ActiveFiltersBar extends StatelessWidget {
  const _ActiveFiltersBar({
    required this.summary,
    required this.onClear,
    required this.onEdit,
  });

  final String summary;
  final VoidCallback onClear;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Material(
        color: AppColors.primary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
            child: Row(
              children: [
                const Icon(
                  Icons.tune_rounded,
                  size: 18,
                  color: AppColors.primaryDark,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    summary.isEmpty ? 'Filtros activos' : summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onClear,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: const Text(
                    'Limpiar',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DiscoverTopBar extends StatelessWidget {
  const _DiscoverTopBar({
    required this.mode,
    required this.onModeSelected,
    required this.onOpenFilters,
    this.filtersActive = false,
  });

  final DiscoverMode mode;
  final ValueChanged<DiscoverMode> onModeSelected;
  final VoidCallback onOpenFilters;
  final bool filtersActive;

  static const _modes = DiscoverMode.values;

  static List<Shadow> get _readShadow => [
        Shadow(
          color: AppColors.surface.withValues(alpha: 0.95),
          blurRadius: 8,
        ),
        Shadow(
          color: AppColors.surface.withValues(alpha: 0.9),
          blurRadius: 2,
          offset: const Offset(0, 0.5),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.go('/home'),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textPrimary,
              shadows: _readShadow,
            ),
            tooltip: 'Volver a mi perfil',
          ),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _modes.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final tab = _modes[index];
                final selected = tab == mode;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => onModeSelected(tab),
                    child: Ink(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withValues(alpha: 0.28)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                        border: selected
                            ? Border.all(
                                color:
                                    AppColors.primary.withValues(alpha: 0.45),
                              )
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          tab.label,
                          style: TextStyle(
                            color: selected
                                ? AppColors.primaryDark
                                : AppColors.textPrimary,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w600,
                            fontSize: 14,
                            shadows: selected ? null : _readShadow,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          IconButton(
            onPressed: onOpenFilters,
            icon: Badge(
              isLabelVisible: filtersActive,
              smallSize: 8,
              backgroundColor: AppColors.accent,
              child: Icon(
                Icons.tune_rounded,
                color: AppColors.primaryDark,
                shadows: _readShadow,
              ),
            ),
            tooltip: 'Filtros',
          ),
        ],
      ),
    );
  }
}
