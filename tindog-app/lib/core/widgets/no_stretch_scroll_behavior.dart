import 'package:flutter/material.dart';

/// Evita el efecto stretch de Material 3 que en algunos emuladores
/// Android provoca glitches visuales (texto invertido) al hacer scroll.
class NoStretchScrollBehavior extends MaterialScrollBehavior {
  const NoStretchScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
