import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class HomeProfileActionRow extends StatelessWidget {
  const HomeProfileActionRow({
    super.key,
    required this.onSettings,
    required this.onAddMedia,
    required this.onSafety,
  });

  final VoidCallback onSettings;
  final VoidCallback onAddMedia;
  final VoidCallback onSafety;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Action(
            icon: Icons.settings_rounded,
            label: 'Ajustes',
            size: 58,
            onTap: onSettings,
          ),
        ),
        Expanded(
          child: _Action(
            icon: Icons.photo_camera_rounded,
            label: 'Media',
            size: 78,
            filled: true,
            badge: Icons.add_rounded,
            onTap: onAddMedia,
          ),
        ),
        Expanded(
          child: _Action(
            icon: Icons.shield_outlined,
            label: 'Seguridad',
            size: 58,
            onTap: onSafety,
          ),
        ),
      ],
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.size,
    required this.onTap,
    this.filled = false,
    this.badge,
  });

  final IconData icon;
  final String label;
  final double size;
  final VoidCallback onTap;
  final bool filled;
  final IconData? badge;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Ink(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: filled
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, AppColors.primaryDark],
                      )
                    : null,
                color: filled ? null : AppColors.card,
                border: filled
                    ? null
                    : Border.all(color: AppColors.border, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: filled
                        ? AppColors.primaryDark.withValues(alpha: 0.35)
                        : AppColors.textPrimary.withValues(alpha: 0.06),
                    blurRadius: filled ? 14 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(
                    icon,
                    size: filled ? 32 : 26,
                    color: filled ? Colors.white : AppColors.textSecondary,
                  ),
                  if (badge != null)
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primaryDark),
                        ),
                        child: Icon(
                          badge,
                          size: 14,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          softWrap: false,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}
