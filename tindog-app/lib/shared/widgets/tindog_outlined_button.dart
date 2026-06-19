import 'package:flutter/material.dart';
import '../../core/feedback/app_haptics.dart';
import '../../core/theme/app_colors.dart';

/// Botón secundario tinDog — mismo look y press en Android e iOS.
class TindogOutlinedButton extends StatefulWidget {
  const TindogOutlinedButton({
    super.key,
    required this.onPressed,
    required this.child,
  });

  final VoidCallback? onPressed;
  final Widget child;

  @override
  State<TindogOutlinedButton> createState() => _TindogOutlinedButtonState();
}

class _TindogOutlinedButtonState extends State<TindogOutlinedButton>
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
    return ScaleTransition(
      scale: _pressScale,
      child: OutlinedButton(
        onPressed: widget.onPressed == null ? null : _handlePress,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          foregroundColor: AppColors.primaryDark,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        child: widget.child,
      ),
    );
  }
}
