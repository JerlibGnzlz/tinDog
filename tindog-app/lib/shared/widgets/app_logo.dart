import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 88,
    this.borderRadius = 20,
  });

  final double size;
  final double borderRadius;

  static const _assetPath = 'assets/branding/app_logo.jpg';

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.asset(
        _assetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          width: size,
          height: size,
          color: AppColors.border,
          child: const Icon(Icons.pets, color: AppColors.primary, size: 40),
        ),
      ),
    );
  }
}

/// Logo con entrada suave para pantallas de auth.
class AnimatedAppLogo extends StatelessWidget {
  const AnimatedAppLogo({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    return AppLogo(size: size)
        .animate()
        .fadeIn(duration: 450.ms, curve: Curves.easeOut)
        .slideY(
          begin: 0.12,
          end: 0,
          duration: 500.ms,
          curve: Curves.easeOutCubic,
        )
        .scale(
          begin: const Offset(0.82, 0.82),
          end: const Offset(1, 1),
          duration: 650.ms,
          curve: Curves.elasticOut,
        );
  }
}
