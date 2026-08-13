import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Vuelve atrás si hay stack; si no, va a Home (evita minimizar la app).
void tindogPopOrHome(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/home');
  }
}
