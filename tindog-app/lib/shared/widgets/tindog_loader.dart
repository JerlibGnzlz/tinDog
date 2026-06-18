import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'paw_particle_path.dart';

/// Loader de marca: patitas que “caminan” (perros y gatos).
class TindogLoader extends StatefulWidget {
  const TindogLoader({
    super.key,
    this.size = 56,
    this.message,
    this.compact = false,
    this.inverted = false,
  });

  final double size;
  final String? message;
  final bool compact;
  /// Patitas claras sobre fondos de color (ej. botón primario).
  final bool inverted;

  @override
  State<TindogLoader> createState() => _TindogLoaderState();
}

class _TindogLoaderState extends State<TindogLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _brandPawColors = [
    AppColors.primaryDark,
    AppColors.primary,
    AppColors.accent,
    AppColors.primary,
  ];

  List<Color> get _pawColors => widget.inverted
      ? [
          Colors.white,
          Colors.white.withValues(alpha: 0.92),
          AppColors.surface,
          Colors.white.withValues(alpha: 0.85),
        ]
      : _brandPawColors;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pawSize = widget.compact ? widget.size * 0.35 : widget.size * 0.42;
    final spacing = widget.compact ? 4.0 : 6.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.size,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(4, (index) {
                  final phase = (_controller.value + index * 0.18) % 1.0;
                  final lift = math.sin(phase * math.pi);
                  final scale = 0.72 + (lift * 0.28);

                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: spacing / 2),
                    child: Transform.translate(
                      offset: Offset(0, -lift * (widget.compact ? 6 : 10)),
                      child: Transform.scale(
                        scale: scale,
                        child: _PawMark(
                          size: pawSize,
                          color: _pawColors[index % _pawColors.length],
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),
        if (widget.message != null) ...[
          SizedBox(height: widget.compact ? 8 : 14),
          Text(
            widget.message!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class _PawMark extends StatelessWidget {
  const _PawMark({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _PawFillPainter(color: color),
    );
  }
}

class _PawFillPainter extends CustomPainter {
  const _PawFillPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      createPawParticlePath(size),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _PawFillPainter oldDelegate) =>
      oldDelegate.color != color;
}
