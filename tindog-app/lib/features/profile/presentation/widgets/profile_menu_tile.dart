import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';

class ProfileMenuTile extends StatelessWidget {
  const ProfileMenuTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isComplete = false,
    this.comingSoon = false,
    this.optional = false,
    this.animationIndex = 0,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isComplete;
  final bool comingSoon;
  /// No cuenta para el % de perfil; muestra chip “Opcional” si no está hecho.
  final bool optional;
  final int animationIndex;

  Widget _chip(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.border.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: comingSoon
            ? _chip(context, 'Próximamente')
            : optional && !isComplete
                ? _chip(context, 'Opcional')
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: animation,
                      child: child,
                    ),
                    child: Icon(
                      isComplete
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      key: ValueKey(isComplete),
                      color: isComplete ? AppColors.accent : AppColors.border,
                    ),
                  ),
        onTap: onTap,
      ),
    )
        .animate()
        .fadeIn(delay: (80 * animationIndex).ms, duration: 320.ms)
        .slideX(
          begin: 0.06,
          end: 0,
          delay: (80 * animationIndex).ms,
          duration: 320.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
