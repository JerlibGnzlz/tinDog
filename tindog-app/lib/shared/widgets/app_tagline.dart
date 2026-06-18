import 'package:flutter/material.dart';
import '../../core/branding/app_branding.dart';
import '../../core/theme/app_colors.dart';

/// Tagline con contraste: línea principal en negrita, cierre en cursiva + acento.
class AppTagline extends StatelessWidget {
  const AppTagline({
    super.key,
    this.compact = false,
    this.onDark = true,
  });

  final bool compact;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final leadSize = compact ? 15.0 : 19.0;
    final trailSize = compact ? 14.0 : 17.0;

    final leadColor = onDark ? Colors.white : AppColors.textPrimary;
    final trailMuted = onDark
        ? Colors.white.withValues(alpha: 0.78)
        : AppColors.textSecondary;
    final accentColor = onDark ? AppColors.surface : AppColors.primaryDark;

    final base = Theme.of(context).textTheme;

    return Text.rich(
      textAlign: TextAlign.center,
      TextSpan(
        style: base.bodyLarge?.copyWith(height: 1.4),
        children: [
          TextSpan(
            text: '${AppBranding.taglineLead}\n',
            style: base.bodyLarge?.copyWith(
              fontSize: leadSize,
              fontWeight: FontWeight.w800,
              color: leadColor,
              letterSpacing: 0.2,
              height: 1.35,
            ),
          ),
          TextSpan(
            text: 'con o sin ',
            style: base.bodyLarge?.copyWith(
              fontSize: trailSize,
              fontWeight: FontWeight.w400,
              fontStyle: FontStyle.italic,
              color: trailMuted,
              height: 1.35,
            ),
          ),
          TextSpan(
            text: 'bigotes',
            style: base.bodyLarge?.copyWith(
              fontSize: trailSize,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
              color: accentColor,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
