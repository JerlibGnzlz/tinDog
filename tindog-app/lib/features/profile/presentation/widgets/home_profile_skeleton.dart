import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/tindog_shimmer.dart';

/// Placeholder del hub Perfil mientras carga pet/perfil.
class HomeProfileSkeleton extends StatelessWidget {
  const HomeProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return Column(
      children: [
        Expanded(
          child: TindogShimmer(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(20, top + 12, 20, 12),
              child: const Column(
                children: [
                  TindogSkeletonBox(width: 128, height: 128, radius: 999),
                  SizedBox(height: 16),
                  TindogSkeletonBox(width: 160, height: 28, radius: 10),
                  SizedBox(height: 14),
                  TindogSkeletonBox(
                    width: double.infinity,
                    height: 52,
                    radius: 16,
                  ),
                  SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ActionSkeleton(circle: 58),
                      _ActionSkeleton(circle: 78),
                      _ActionSkeleton(circle: 58),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        TindogShimmer(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenH,
              0,
              AppSpacing.screenH,
              AppSpacing.md,
            ),
            child: const TindogSkeletonBox(
              width: double.infinity,
              height: 148,
              radius: 20,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionSkeleton extends StatelessWidget {
  const _ActionSkeleton({required this.circle});

  final double circle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TindogSkeletonBox(width: circle, height: circle, radius: 999),
        const SizedBox(height: 10),
        const TindogSkeletonBox(width: 64, height: 12, radius: 6),
      ],
    );
  }
}
