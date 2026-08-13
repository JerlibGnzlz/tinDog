import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Intensidad del fondo de marca tinDog.
enum TindogAtmosphereKind {
  /// Tabs de trabajo: lavado suave, sin huellas.
  shell,

  /// Hub Perfil: gradiente + blob + huellas.
  hub,
}

/// Atmósfera de marca compartida. [shell] une las tabs; [hub] es identidad.
class TindogBrandAtmosphere extends StatelessWidget {
  const TindogBrandAtmosphere({
    super.key,
    required this.kind,
    required this.child,
  });

  final TindogAtmosphereKind kind;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(gradient: _gradient),
        ),
        if (kind == TindogAtmosphereKind.hub) ...[
          Positioned(
            top: -56,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: Container(
                  width: 360,
                  height: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(180),
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.62),
                        AppColors.primary.withValues(alpha: 0.34),
                        AppColors.primary.withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.35, 0.65, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 90,
            right: -40,
            child: IgnorePointer(
              child: Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent.withValues(alpha: 0.22),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 70,
            left: -30,
            child: IgnorePointer(
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.18),
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _PawPrintsPainter()),
            ),
          ),
        ] else ...[
          // Halo muy suave arriba — marca sin ruido.
          Positioned(
            top: -80,
            left: -40,
            right: -40,
            child: IgnorePointer(
              child: Container(
                height: 220,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.2),
                    radius: 0.9,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.18),
                      AppColors.primary.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
          ),
        ],
        child,
      ],
    );
  }

  LinearGradient get _gradient => switch (kind) {
        TindogAtmosphereKind.hub => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFC5DBA8),
              Color(0xFFDCEBC8),
              Color(0xFFF0E2C4),
              Color(0xFFE8D9BC),
            ],
            stops: [0.0, 0.32, 0.68, 1.0],
          ),
        TindogAtmosphereKind.shell => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE4EED6),
              AppColors.surface,
              Color(0xFFF5EDDC),
            ],
            stops: [0.0, 0.45, 1.0],
          ),
      };
}

class _PawPrintsPainter extends CustomPainter {
  const _PawPrintsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryDark.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;

    final spots = <(double, double, double, double)>[
      (0.12, 0.16, 1.35, -0.4),
      (0.84, 0.12, 1.2, 0.5),
      (0.16, 0.38, 1.15, 0.3),
      (0.90, 0.36, 1.3, -0.55),
      (0.08, 0.58, 1.1, 0.2),
      (0.80, 0.55, 1.15, -0.25),
      (0.22, 0.78, 1.05, -0.35),
      (0.72, 0.82, 1.2, 0.4),
    ];

    for (final (dx, dy, scale, rot) in spots) {
      canvas.save();
      canvas.translate(size.width * dx, size.height * dy);
      canvas.rotate(rot);
      canvas.scale(scale);
      _drawPaw(canvas, paint);
      canvas.restore();
    }
  }

  void _drawPaw(Canvas canvas, Paint paint) {
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 6), width: 18, height: 14),
      paint,
    );
    const toes = <Offset>[
      Offset(-10, -6),
      Offset(-3.5, -10),
      Offset(3.5, -10),
      Offset(10, -6),
    ];
    for (final toe in toes) {
      canvas.drawOval(
        Rect.fromCenter(center: toe, width: 7, height: 9),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
