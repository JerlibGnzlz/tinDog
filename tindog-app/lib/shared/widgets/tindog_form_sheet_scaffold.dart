import 'package:flutter/material.dart';

/// Sheet con formularios: respeta teclado (`viewInsets`) + safe area inferior.
///
/// Uso típico dentro de `showModalBottomSheet(isScrollControlled: true)`.
class TindogFormSheetScaffold extends StatelessWidget {
  const TindogFormSheetScaffold({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 16),
    this.scrollable = true,
    this.maxHeightFactor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool scrollable;

  /// Si se setea (ej. 0.9), limita altura al % de pantalla.
  final double? maxHeightFactor;

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final screenH = MediaQuery.sizeOf(context).height;
    final maxH = maxHeightFactor == null
        ? null
        : (screenH - keyboard) * maxHeightFactor!;

    Widget body = scrollable
        ? SingleChildScrollView(
            padding: padding,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: child,
          )
        : Padding(padding: padding, child: child);

    if (maxH != null) {
      body = scrollable
          ? ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxH.clamp(120, screenH)),
              child: body,
            )
          : SizedBox(
              height: maxH.clamp(120, screenH),
              child: body,
            );
    }

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboard),
      child: SafeArea(
        top: false,
        child: body,
      ),
    );
  }
}
