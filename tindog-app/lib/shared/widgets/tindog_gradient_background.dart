import 'package:flutter/material.dart';

/// Fondo con degradado que ocupa todo el espacio disponible del [Scaffold.body].
class TindogGradientBackground extends StatelessWidget {
  const TindogGradientBackground({
    super.key,
    required this.gradient,
    required this.child,
  });

  final Gradient gradient;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: gradient),
      child: SizedBox.expand(child: child),
    );
  }
}
