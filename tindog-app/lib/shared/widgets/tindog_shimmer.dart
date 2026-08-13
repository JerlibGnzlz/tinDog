import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';

/// Base shimmer tinDog (crema / borde).
class TindogShimmer extends StatelessWidget {
  const TindogShimmer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.border.withValues(alpha: 0.55),
      highlightColor: AppColors.card,
      child: child,
    );
  }
}

class TindogSkeletonBox extends StatelessWidget {
  const TindogSkeletonBox({
    super.key,
    this.width,
    this.height,
    this.radius = 12,
  });

  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
