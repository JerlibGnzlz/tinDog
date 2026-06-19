import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Scroll idéntico en Android e iOS (sin diferencias de plataforma).
class TindogScrollBehavior extends MaterialScrollBehavior {
  const TindogScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}
