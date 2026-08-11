import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class DiscoverActions extends StatelessWidget {
  const DiscoverActions({
    super.key,
    required this.onPass,
    required this.onLike,
    this.onRewind,
    this.onSuperLike,
    this.onBoost,
    this.canRewind = false,
  });

  final VoidCallback onPass;
  final VoidCallback onLike;
  final VoidCallback? onRewind;
  final VoidCallback? onSuperLike;
  final VoidCallback? onBoost;
  final bool canRewind;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _Btn(
          icon: Icons.replay_rounded,
          color: const Color(0xFFD4A017),
          size: 46,
          onTap: canRewind ? onRewind : null,
          enabled: canRewind,
        ),
        _Btn(
          icon: Icons.close_rounded,
          color: AppColors.textSecondary,
          size: 62,
          iconSize: 32,
          onTap: onPass,
        ),
        _Btn(
          icon: Icons.star_rounded,
          color: const Color(0xFF5B8FA8),
          size: 46,
          onTap: onSuperLike,
        ),
        _Btn(
          icon: Icons.favorite_rounded,
          color: AppColors.accent,
          size: 62,
          iconSize: 30,
          onTap: onLike,
        ),
        _Btn(
          icon: Icons.bolt_rounded,
          color: AppColors.primaryDark,
          size: 46,
          onTap: onBoost,
        ),
      ],
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn({
    required this.icon,
    required this.color,
    required this.size,
    required this.onTap,
    this.iconSize,
    this.enabled = true,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double? iconSize;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = enabled ? color : color.withValues(alpha: 0.35);
    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: const CircleBorder(),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.card,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: effectiveColor, size: iconSize ?? 22),
        ),
      ),
    );
  }
}
