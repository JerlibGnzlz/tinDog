import 'package:flutter/material.dart';
import '../../../../core/feedback/app_haptics.dart';
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
          feel: _PressFeel.rewind,
        ),
        _Btn(
          icon: Icons.close_rounded,
          color: AppColors.textSecondary,
          size: 62,
          iconSize: 32,
          onTap: onPass,
          feel: _PressFeel.pass,
        ),
        _Btn(
          icon: Icons.star_rounded,
          color: const Color(0xFF5B8FA8),
          size: 46,
          onTap: onSuperLike,
          feel: _PressFeel.soft,
        ),
        _Btn(
          icon: Icons.favorite_rounded,
          color: AppColors.accent,
          size: 62,
          iconSize: 30,
          onTap: onLike,
          feel: _PressFeel.like,
        ),
        _Btn(
          icon: Icons.bolt_rounded,
          color: AppColors.primaryDark,
          size: 46,
          onTap: onBoost,
          feel: _PressFeel.soft,
        ),
      ],
    );
  }
}

enum _PressFeel { rewind, pass, like, soft }

class _Btn extends StatefulWidget {
  const _Btn({
    required this.icon,
    required this.color,
    required this.size,
    required this.onTap,
    required this.feel,
    this.iconSize,
    this.enabled = true,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double? iconSize;
  final VoidCallback? onTap;
  final bool enabled;
  final _PressFeel feel;

  @override
  State<_Btn> createState() => _BtnState();
}

class _BtnState extends State<_Btn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 240),
    );
    _scale = Tween<double>(begin: 1, end: 0.88).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _hapticIfNeeded() {
    // Like / Pass / Rewind ya vibran en la card o en discover_screen.
    if (widget.feel == _PressFeel.soft) {
      AppHaptics.light();
    }
  }

  Future<void> _onTapDown(TapDownDetails _) async {
    if (!widget.enabled) return;
    AppHaptics.selection();
    await _controller.forward();
  }

  Future<void> _onTapUp(TapUpDetails _) async {
    if (!widget.enabled) return;
    _hapticIfNeeded();
    widget.onTap?.call();
    if (!mounted) return;
    await _controller.reverse();
  }

  Future<void> _onTapCancel() async {
    if (!widget.enabled) return;
    if (!mounted) return;
    await _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        widget.enabled ? widget.color : widget.color.withValues(alpha: 0.35);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.enabled ? _onTapDown : null,
      onTapUp: widget.enabled ? _onTapUp : null,
      onTapCancel: widget.enabled ? _onTapCancel : null,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: widget.size,
          height: widget.size,
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
          child: Icon(
            widget.icon,
            color: effectiveColor,
            size: widget.iconSize ?? 22,
          ),
        ),
      ),
    );
  }
}
