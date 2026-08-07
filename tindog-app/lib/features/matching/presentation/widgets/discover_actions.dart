import 'package:flutter/material.dart';

class DiscoverActions extends StatelessWidget {
  const DiscoverActions({
    super.key,
    required this.onPass,
    required this.onLike,
    this.onRewind,
    this.onSuperLike,
    this.onBoost,
  });

  final VoidCallback onPass;
  final VoidCallback onLike;
  final VoidCallback? onRewind;
  final VoidCallback? onSuperLike;
  final VoidCallback? onBoost;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _Btn(
          icon: Icons.replay_rounded,
          color: const Color(0xFFF5C518),
          size: 46,
          onTap: onRewind,
        ),
        _Btn(
          icon: Icons.close_rounded,
          color: Colors.white,
          size: 62,
          iconSize: 32,
          onTap: onPass,
        ),
        _Btn(
          icon: Icons.star_rounded,
          color: const Color(0xFF4DB5FF),
          size: 46,
          onTap: onSuperLike,
        ),
        _Btn(
          icon: Icons.favorite_rounded,
          color: const Color(0xFFFF4458),
          size: 62,
          iconSize: 30,
          onTap: onLike,
        ),
        _Btn(
          icon: Icons.bolt_rounded,
          color: const Color(0xFFA56BFF),
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
  });

  final IconData icon;
  final Color color;
  final double size;
  final double? iconSize;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: color, size: iconSize ?? 22),
        ),
      ),
    );
  }
}
