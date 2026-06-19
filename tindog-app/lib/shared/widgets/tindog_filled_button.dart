import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/feedback/app_haptics.dart';
import 'tindog_loader.dart';

enum _ButtonVisual { idle, loading, success }

class TindogFilledButton extends StatefulWidget {
  const TindogFilledButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.loading = false,
    this.success = false,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final bool loading;
  final bool success;

  @override
  State<TindogFilledButton> createState() => _TindogFilledButtonState();
}

class _TindogFilledButtonState extends State<TindogFilledButton>
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

  bool get _isInteractive =>
      widget.onPressed != null && !widget.loading && !widget.success;

  _ButtonVisual get _visual {
    if (widget.success) return _ButtonVisual.success;
    if (widget.loading) return _ButtonVisual.loading;
    return _ButtonVisual.idle;
  }

  Future<void> _handlePress() async {
    if (!_isInteractive) return;
    AppHaptics.light();
    await _pressController.forward();
    await _pressController.reverse();
    if (!mounted) return;
    widget.onPressed!();
  }

  Widget _buildContent() {
    switch (_visual) {
      case _ButtonVisual.loading:
        return const TindogLoader(size: 28, compact: true, inverted: true);
      case _ButtonVisual.success:
        return const Icon(Icons.check_rounded, color: Colors.white, size: 28)
            .animate(key: const ValueKey('save-success-check'))
            .scale(
              begin: const Offset(0.2, 0.2),
              end: const Offset(1, 1),
              duration: 500.ms,
              curve: Curves.elasticOut,
            );
      case _ButtonVisual.idle:
        return widget.child;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pressScale,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: _isInteractive ? AppGradients.primaryButton : null,
          color: _isInteractive ? null : AppColors.primary.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isInteractive
              ? [
                  BoxShadow(
                    color: AppColors.primaryDark.withValues(alpha: 0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.18),
                    blurRadius: 0,
                    offset: const Offset(0, 1),
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            disabledForegroundColor: Colors.white,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: widget.onPressed == null ? null : _handlePress,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: KeyedSubtree(
              key: ValueKey(_visual),
              child: _buildContent(),
            ),
          ),
        ),
      ),
    );
  }
}
