import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/feedback/app_feedback.dart';
import '../../../core/network/session_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/tindog_loader.dart';
import 'discover_providers.dart';
import 'widgets/discover_actions.dart';
import 'widgets/discover_card.dart';
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

  @override
  Widget build(BuildContext context) {
    final deck = ref.watch(discoverDeckProvider);
    final current = deck.current;
    final topInset = MediaQuery.paddingOf(context).top;

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
                    key: ValueKey(current.id),
                    candidate: current,
                    controller: _cardController,
                    storyTopInset: topInset + 52,
                    onDecision: _onDecision,
                    onOpenDetails: () {
                      showTindogInfoSnackBar(
                        context,
                        'Detalle de ${current.name} — próximamente',
                      );
                    },
                    bottomBar: DiscoverActions(
                      onPass: _cardController.pass,
                      onLike: _cardController.like,
                      onRewind: () => showTindogInfoSnackBar(
                        context,
                        'Rewind — próximamente',
                      ),
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
                  Center(
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
                          const Text(
                            'No hay más perfiles por ahora',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Volvé más tarde o completá tu perfil para aparecer ante otros.',
                            style: TextStyle(
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
                            onPressed: () => ref
                                .read(discoverDeckProvider.notifier)
                                .reload(),
                            child: const Text('Actualizar'),
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.only(top: topInset),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.surface.withValues(alpha: 0.92),
                          AppColors.surface.withValues(alpha: 0),
                        ],
                      ),
                    ),
                    child: const _DiscoverTopBar(),
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

class _DiscoverTopBar extends StatelessWidget {
  const _DiscoverTopBar();

  static const _tabs = ['Para ti', 'Cerca', 'Razas', 'Juego'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.go('/home'),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textPrimary,
            ),
            tooltip: 'Volver a mi perfil',
          ),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _tabs.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final selected = index == 0;
                return Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withValues(alpha: 0.22)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    border: selected
                        ? Border.all(color: AppColors.primary.withValues(alpha: 0.4))
                        : null,
                  ),
                  child: Text(
                    _tabs[index],
                    style: TextStyle(
                      color: selected
                          ? AppColors.primaryDark
                          : AppColors.textSecondary,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                );
              },
            ),
          ),
          IconButton(
            onPressed: () => showTindogInfoSnackBar(
              context,
              'Filtros — próximamente',
            ),
            icon: const Icon(
              Icons.tune_rounded,
              color: AppColors.primaryDark,
            ),
            tooltip: 'Filtros',
          ),
        ],
      ),
    );
  }
}
