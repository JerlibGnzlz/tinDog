import 'package:flutter/material.dart';

/// Escala de spacing de la app (múltiplos de 4).
abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;

  /// Padding horizontal de pantallas con título.
  static const screenH = 20.0;
}

/// Jerarquía tipográfica compartida.
abstract final class AppTypography {
  /// Título de tab (Chats, Likes, Explorar…).
  static const screenTitle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 1.15,
    letterSpacing: -0.3,
  );

  /// Nombre grande en hub / ficha.
  static const displayName = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    height: 1.15,
  );

  /// Sección dentro de una pantalla (Matches nuevos, Buscar perros…).
  static const sectionTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    height: 1.2,
  );

  static const body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static const bodySecondary = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static const caption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.35,
  );
}
