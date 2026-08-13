import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'paw_particle_path.dart';

/// Loader de marca: rastro de huellas que “caminan”.
///
/// En [compact] / [inverted] (botones) usa una fila corta;
/// en pantallas completas, el rastro curvo + halo de marca.
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
    AppColors.primaryDark,
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
      duration: Duration(milliseconds: widget.compact ? 1000 : 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return _CompactPawBounce(
        controller: _controller,
        size: widget.size,
        inverted: widget.inverted,
        colors: _pawColors,
        message: widget.message,
      );
    }

    return _BrandPawTrail(
      controller: _controller,
      size: widget.size,
      colors: _pawColors,
      message: widget.message,
    );
  }
}

/// Pantalla completa: arco de huellas + glow.
class _BrandPawTrail extends StatelessWidget {
  const _BrandPawTrail({
    required this.controller,
    required this.size,
    required this.colors,
    this.message,
  });

  final AnimationController controller;
  final double size;
  final List<Color> colors;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final trailW = math.max(size * 2.6, 168.0);
    final trailH = math.max(size * 1.55, 96.0);
    final pawSize = size * 0.48;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: trailW + 48,
          height: trailH + 36,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Halo de marca detrás del rastro.
              IgnorePointer(
                child: Container(
                  width: trailW * 0.95,
                  height: trailH * 1.1,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.28),
                        AppColors.primary.withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: controller,
                builder: (context, _) {
                  const count = 5;
                  return SizedBox(
                    width: trailW,
                    height: trailH,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: List.generate(count, (index) {
                        final t = index / (count - 1);
                        // Arco suave de izquierda a derecha (como un paseo).
                        final x = t * trailW;
                        final y = trailH * 0.55 +
                            math.sin(t * math.pi) * (trailH * 0.28);
                        final rot = (index.isEven ? -0.38 : 0.38);

                        // Onda que recorre el rastro (huella “fresca”).
                        final wave = (controller.value - t * 0.72 + 1.0) % 1.0;
                        final freshness = math.exp(-math.pow(wave - 0.18, 2) / 0.02);
                        final opacity = 0.22 + freshness * 0.78;
                        final scale = 0.72 + freshness * 0.38;

                        return Positioned(
                          left: x - pawSize / 2,
                          top: y - pawSize / 2,
                          child: Opacity(
                            opacity: opacity.clamp(0.0, 1.0),
                            child: Transform.rotate(
                              angle: rot,
                              child: Transform.scale(
                                scale: scale,
                                child: _PawMark(
                                  size: pawSize,
                                  color: colors[index % colors.length],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 8),
          Text(
            message!,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
              height: 1.25,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// Compacto para botones / espacios chicos.
class _CompactPawBounce extends StatelessWidget {
  const _CompactPawBounce({
    required this.controller,
    required this.size,
    required this.inverted,
    required this.colors,
    this.message,
  });

  final AnimationController controller;
  final double size;
  final bool inverted;
  final List<Color> colors;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final pawSize = size * 0.35;
    const spacing = 4.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: size,
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(4, (index) {
                  final phase = (controller.value + index * 0.18) % 1.0;
                  final lift = math.sin(phase * math.pi);
                  final scale = 0.72 + (lift * 0.28);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: spacing / 2),
                    child: Transform.translate(
                      offset: Offset(0, -lift * 6),
                      child: Transform.scale(
                        scale: scale,
                        child: _PawMark(
                          size: pawSize,
                          color: colors[index % colors.length],
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 8),
          Text(
            message!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: inverted ? Colors.white : AppColors.textSecondary,
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
