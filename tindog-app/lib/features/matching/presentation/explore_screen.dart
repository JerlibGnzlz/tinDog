import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/feedback/app_feedback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../profile/presentation/profile_providers.dart';
import 'discover_filters.dart';
import 'discover_providers.dart';
import 'explore_categories.dart';
import 'widgets/explore_category_card.dart';

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  void _openDiscover(
    WidgetRef ref,
    BuildContext context,
    ExploreCategory category,
  ) {
    final mode = category.mode;
    if (mode == null) return;

    final current = ref.read(discoverFiltersProvider);
    final petBreed = ref.read(myPetProvider).valueOrNull?.breed?.trim();

    final next = switch (mode) {
      DiscoverMode.near => current.copyWith(mode: DiscoverMode.near),
      DiscoverMode.forYou => current.copyWith(mode: DiscoverMode.forYou),
      DiscoverMode.withVideos =>
        current.copyWith(mode: DiscoverMode.withVideos),
      DiscoverMode.breed => current.copyWith(
          mode: DiscoverMode.breed,
          breed: (petBreed != null && petBreed.isNotEmpty) ? petBreed : null,
          clearBreed: petBreed == null || petBreed.isEmpty,
        ),
    };

    ref.read(discoverFiltersProvider.notifier).state = next;
    context.go('/discover');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                topInset + AppSpacing.md,
                AppSpacing.screenH,
                0,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Explorar',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    'Buscá perros para match o, más adelante, servicios cerca',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.xl,
                AppSpacing.screenH,
                AppSpacing.sm,
              ),
              child: Text(
                'Buscar perros',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.9,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final category = exploreDogShortcuts[index];
                  return ExploreCategoryCard(
                    category: category,
                    onTap: () => _openDiscover(ref, context, category),
                  );
                },
                childCount: exploreDogShortcuts.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.lg,
                AppSpacing.screenH,
                AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Servicios cerca',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    'Próximamente',
                    style: TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                0,
                AppSpacing.screenH,
                AppSpacing.sm,
              ),
              child: Text(
                'Veterinarias, paseos, refugios y pet shops',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.25,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.95,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final category = exploreServiceTeasers[index];
                  return ExploreCategoryCard(
                    category: category,
                    compact: true,
                    muted: true,
                    onTap: () => showTindogInfoSnackBar(
                      context,
                      '${category.title}: próximamente en tinDog',
                    ),
                  );
                },
                childCount: exploreServiceTeasers.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
