import 'package:flutter/material.dart';
import '../../core/branding/app_branding.dart';
import '../../core/theme/app_colors.dart';

/// Tagline de marca: lead en negrita + trail con acento.
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
    final leadSize = compact ? 16.0 : 20.0;
    final trailSize = compact ? 14.5 : 17.0;

    final leadColor = onDark ? Colors.white : AppColors.textPrimary;
    final trailColor = onDark
        ? Colors.white.withValues(alpha: 0.88)
        : AppColors.textSecondary;

    final base = Theme.of(context).textTheme;

    return Text.rich(
      textAlign: TextAlign.center,
      TextSpan(
        style: base.bodyLarge?.copyWith(height: 1.45),
        children: [
          TextSpan(
            text: '${AppBranding.taglineLead}\n',
            style: base.bodyLarge?.copyWith(
              fontSize: leadSize,
              fontWeight: FontWeight.w800,
              color: leadColor,
              letterSpacing: 0.15,
              height: 1.35,
            ),
          ),
          TextSpan(
            text: AppBranding.taglineTrail,
            style: base.bodyLarge?.copyWith(
              fontSize: trailSize,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
              color: trailColor,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
