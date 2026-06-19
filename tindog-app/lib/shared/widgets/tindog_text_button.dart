import 'package:flutter/material.dart';
import '../../core/feedback/app_haptics.dart';
import '../../core/theme/app_colors.dart';

/// Botón de texto tinDog — links y acciones terciarias, igual en ambas plataformas.
class TindogTextButton extends StatefulWidget {
  const TindogTextButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.foregroundColor,
    this.fontWeight = FontWeight.w500,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Color? foregroundColor;
  final FontWeight fontWeight;

  @override
  State<TindogTextButton> createState() => _TindogTextButtonState();
}

class _TindogTextButtonState extends State<TindogTextButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _pressScale;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _pressScale = Tween<double>(begin: 1, end: 0.96).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  Future<void> _handlePress() async {
    if (widget.onPressed == null) return;
    AppHaptics.light();
    await _pressController.forward();
    await _pressController.reverse();
    if (!mounted) return;
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.foregroundColor ?? AppColors.primary;

    return ScaleTransition(
      scale: _pressScale,
      child: TextButton(
        onPressed: widget.onPressed == null ? null : _handlePress,
        style: TextButton.styleFrom(
          foregroundColor: color,
          textStyle: TextStyle(
            fontWeight: widget.fontWeight,
            fontSize: 16,
          ),
        ),
        child: widget.child,
      ),
    );
  }
}
