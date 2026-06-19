import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Degradados de marca tinDog (inspiración Tinder, paleta propia).
abstract final class AppGradients {
  /// Welcome — diagonal suave, verde salvia → bosque.
  static const authHero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFB5CF8F),
      AppColors.primary,
      AppColors.primaryDark,
      AppColors.accent,
    ],
    stops: [0.0, 0.32, 0.68, 1.0],
  );

  /// Login / registro — lavado sutil de arriba a abajo, sin bandas visibles.
  static const authSoft = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFF0F5E8),
      Color(0xFFF5F0E4),
      AppColors.surface,
      AppColors.surface,
    ],
    stops: [0.0, 0.28, 0.62, 1.0],
  );

  /// Botones principales — brillo arriba, profundidad abajo.
  static const primaryButton = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFB5D088),
      AppColors.primary,
      Color(0xFF5A7340),
    ],
    stops: [0.0, 0.48, 1.0],
  );

  /// Barra de progreso del perfil.
  static const progress = LinearGradient(
    colors: [AppColors.primary, AppColors.accent],
  );
}
