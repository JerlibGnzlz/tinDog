import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class SwipePreviewActions extends StatelessWidget {
  const SwipePreviewActions({
    super.key,
    required this.onPass,
    required this.onLike,
    this.compact = false,
  });

  final VoidCallback onPass;
  final VoidCallback onLike;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final passSize = compact ? 46.0 : 52.0;
    final likeSize = compact ? 54.0 : 58.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ActionButton(
          icon: Icons.close_rounded,
          iconColor: const Color(0xFFEF5350),
          borderColor: const Color(0xFFEF5350),
          backgroundColor: Colors.white,
          onPressed: onPass,
          semanticLabel: 'Vista previa de pass',
          size: passSize,
          iconSize: compact ? 24 : 26,
        ),
        SizedBox(width: compact ? 22 : 26),
        _ActionButton(
          icon: Icons.favorite_rounded,
          iconColor: Colors.white,
          borderColor: AppColors.accent,
          backgroundColor: AppColors.accent,
          onPressed: onLike,
          semanticLabel: 'Vista previa de like',
          size: likeSize,
          iconSize: compact ? 26 : 28,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.iconColor,
    required this.borderColor,
    required this.backgroundColor,
    required this.onPressed,
    required this.semanticLabel,
    this.size = 56,
    this.iconSize = 28,
  });

  final IconData icon;
  final Color iconColor;
  final Color borderColor;
  final Color backgroundColor;
  final VoidCallback onPressed;
  final String semanticLabel;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Ink(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: iconSize),
          ),
        ),
      ),
    );
  }
}
