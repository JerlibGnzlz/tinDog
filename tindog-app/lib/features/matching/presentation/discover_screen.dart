import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/feedback/app_feedback.dart';
import '../../../core/network/session_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/pet_photo_viewer_screen.dart';
import '../../../shared/widgets/pet_video_player_screen.dart';
import '../../../shared/widgets/tindog_loader.dart';
import '../../../shared/models/swipe_preview_media.dart';
import '../../profile/presentation/profile_providers.dart';
import 'discover_filters.dart';
import 'discover_providers.dart';
import 'widgets/discover_actions.dart';
import 'widgets/discover_card.dart';
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
        final goChat = await showMatchCelebrationDialog(
          context,
          petName: name,
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

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (deck.isLoading && current == null)
                  const Center(child: TindogLoader(message: 'Buscando…'))
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
                    title: filters.mode == DiscoverMode.play
                        ? 'Modo juego vacío'
                        : 'No hay más perfiles',
                    subtitle: filters.emptyMessage(
                      hasGps: hasGps,
                      hasOwnBreed: hasOwnBreed,
                    ),
                    primaryLabel: filters.mode == DiscoverMode.near && !hasGps
                        ? 'Activar GPS'
                        : filters.mode == DiscoverMode.breed &&
                                !hasOwnBreed &&
                                (filters.breed == null ||
                                    filters.breed!.trim().isEmpty)
                            ? 'Elegir raza'
                            : 'Actualizar',
                    onPrimary: () async {
                      if (filters.mode == DiscoverMode.near && !hasGps) {
                        context.push('/profile/location');
                        return;
                      }
                      if (filters.mode == DiscoverMode.breed &&
                          (filters.breed == null ||
                              filters.breed!.trim().isEmpty) &&
                          !hasOwnBreed) {
                        await _openFilters();
                        return;
                      }
                      ref.read(discoverDeckProvider.notifier).reload();
                    },
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
                    child: _DiscoverTopBar(
                      mode: filters.mode,
                      filtersActive: filters.hasExtraFilters,
                      onModeSelected: (mode) {
                        ref.read(discoverFiltersProvider.notifier).state =
                            filters.copyWith(mode: mode);
                      },
                      onOpenFilters: _openFilters,
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
    required this.title,
    required this.subtitle,
    required this.primaryLabel,
    required this.onPrimary,
    this.onRewind,
  });

  final String title;
  final String subtitle;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback? onRewind;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pets_rounded,
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: onPrimary,
              child: Text(primaryLabel),
            ),
            if (onRewind != null) ...[
              const SizedBox(height: 12),
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
