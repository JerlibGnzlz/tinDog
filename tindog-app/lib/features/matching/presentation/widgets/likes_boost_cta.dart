import 'package:flutter/material.dart';
import '../../../../core/feedback/app_feedback.dart';
import '../../../../core/theme/app_colors.dart';

/// CTA de Boost en Likes (stub hasta el módulo de pagos).
class LikesBoostCta extends StatelessWidget {
  const LikesBoostCta({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: InkWell(
        onTap: () => showTindogInfoSnackBar(
          context,
          'Boost — próximamente. Empujá tu perfil para más likes.',
        ),
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.92),
                AppColors.primaryDark,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt_rounded, color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text(
                'Quiero un boost',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
