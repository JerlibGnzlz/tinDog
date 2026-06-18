import 'package:flutter/material.dart';

/// Forma de patita para partículas de celebración al completar el perfil.
Path createPawParticlePath(Size size) {
  final w = size.width;
  final h = size.height;
  final path = Path();

  void addPad(Offset center, double padW, double padH) {
    path.addOval(
      Rect.fromCenter(center: center, width: padW, height: padH),
    );
  }

  // Almohadilla principal
  addPad(Offset(w * 0.5, h * 0.7), w * 0.52, h * 0.36);

  // Deditos
  final toeW = w * 0.24;
  final toeH = h * 0.28;
  addPad(Offset(w * 0.24, h * 0.34), toeW, toeH);
  addPad(Offset(w * 0.4, h * 0.18), toeW, toeH);
  addPad(Offset(w * 0.6, h * 0.18), toeW, toeH);
  addPad(Offset(w * 0.76, h * 0.34), toeW, toeH);

  return path;
}
