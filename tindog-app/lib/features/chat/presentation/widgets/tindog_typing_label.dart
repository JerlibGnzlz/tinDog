import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Puntos animados «escribiendo…» (estilo WhatsApp).
class TindogTypingLabel extends StatefulWidget {
  const TindogTypingLabel({
    super.key,
    this.prefix = 'está escribiendo',
    this.style = const TextStyle(
      color: AppColors.primaryDark,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 1.1,
    ),
  });

  final String prefix;
  final TextStyle style;

  @override
  State<TindogTypingLabel> createState() => _TindogTypingLabelState();
}

class _TindogTypingLabelState extends State<TindogTypingLabel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        // 0–3 puntos visibles en ciclo.
        final dots = 1 + ((t * 3).floor() % 3);
        return Text(
          '${widget.prefix}${'.' * dots}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: widget.style,
        );
      },
    );
  }
}
