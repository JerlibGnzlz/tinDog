import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _appChannel = MethodChannel('com.tindog.tindog_app/app');

/// Diálogo de confirmación al intentar salir de la app (no cierra sesión).
///
/// Pensado para Android (atrás en la raíz). En iOS el gesto Home no se
/// intercepta (guideline de Apple); el diálogo aplica si el stack hace pop.
Future<bool> showConfirmAppExitDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('¿Salir de tinDog?'),
        content: const Text(
          'Vas a dejar la app. Tu sesión seguirá iniciada.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Salir'),
          ),
        ],
      );
    },
  );
  return result == true;
}

/// Manda la app a segundo plano sin destruir el Activity (comportamiento normal).
///
/// [SystemNavigator.pop] sí cierra el Activity y al reabrir el "atrás" deja de
/// pasar por Flutter; por eso en Android usamos `moveTaskToBack`.
Future<void> defaultAppExit() async {
  if (kIsWeb) return;
  if (defaultTargetPlatform == TargetPlatform.android) {
    try {
      await _appChannel.invokeMethod<void>('moveToBackground');
      return;
    } on MissingPluginException {
      // Tests / hot-restart sin canal: fallback.
    } on PlatformException {
      // ignore — fallback abajo
    }
  }
  // iOS: no-op habitual; en emuladores Android sin canal, cierra Activity.
  await SystemNavigator.pop();
}

/// Intercepta el pop del navigator en la raíz y pide confirmación antes de salir.
///
/// [onExit] es inyectable para tests.
class ConfirmAppExitScope extends StatefulWidget {
  const ConfirmAppExitScope({
    super.key,
    required this.child,
    this.onExit = defaultAppExit,
  });

  final Widget child;
  final Future<void> Function() onExit;

  @override
  State<ConfirmAppExitScope> createState() => _ConfirmAppExitScopeState();
}

class _ConfirmAppExitScopeState extends State<ConfirmAppExitScope>
    with WidgetsBindingObserver {
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Tras volver de segundo plano, siempre permitir de nuevo el diálogo.
    if (state == AppLifecycleState.resumed) {
      _confirming = false;
    }
  }

  Future<void> _handlePopAttempt() async {
    if (_confirming || !mounted) return;
    _confirming = true;
    try {
      final shouldExit = await showConfirmAppExitDialog(context);
      if (!shouldExit || !mounted) return;
      // Liberar el flag ANTES de ir a background (el Future puede pausarse).
      _confirming = false;
      await widget.onExit();
    } finally {
      _confirming = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handlePopAttempt();
      },
      child: widget.child,
    );
  }
}
