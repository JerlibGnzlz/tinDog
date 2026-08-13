import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/tindog_shimmer.dart';

/// Placeholder de ficha Desliza mientras carga el deck.
class DiscoverCardSkeleton extends StatelessWidget {
  const DiscoverCardSkeleton({super.key, this.topInset = 0});

  final double topInset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12, topInset + 8, 12, 12),
      child: Column(
        children: [
          Expanded(
            child: TindogShimmer(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const TindogSkeletonBox(width: 88, height: 22, radius: 999),
                        const SizedBox(height: 14),
                        const TindogSkeletonBox(width: 180, height: 28, radius: 10),
                        const SizedBox(height: 10),
                        const TindogSkeletonBox(width: 140, height: 16, radius: 8),
                        const SizedBox(height: 10),
                        const TindogSkeletonBox(
                          width: double.infinity,
                          height: 14,
                          radius: 8,
                        ),
                        const SizedBox(height: 6),
                        const TindogSkeletonBox(width: 220, height: 14, radius: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TindogShimmer(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final size in [46.0, 62.0, 46.0, 62.0, 46.0])
                  TindogSkeletonBox(width: size, height: size, radius: 999),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
