import 'package:flutter/material.dart';
import '../../../../shared/widgets/tindog_brand_atmosphere.dart';

/// Fondo ilustrativo del hub Perfil (marca completa).
class HomeProfileAtmosphere extends StatelessWidget {
  const HomeProfileAtmosphere({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TindogBrandAtmosphere(
      kind: TindogAtmosphereKind.hub,
      child: child,
    );
  }
}
