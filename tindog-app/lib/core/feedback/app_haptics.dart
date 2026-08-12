import 'package:flutter/services.dart';

/// Hápticos unificados de tinDog.
abstract final class AppHaptics {
  static void light() => HapticFeedback.lightImpact();

  static void selection() => HapticFeedback.selectionClick();

  static void success() => HapticFeedback.mediumImpact();

  static void error() => HapticFeedback.heavyImpact();

  /// Like / swipe derecha.
  static void like() => HapticFeedback.mediumImpact();

  /// Pass / swipe izquierda.
  static void pass() => HapticFeedback.lightImpact();

  /// Match mutuo.
  static void match() {
    HapticFeedback.heavyImpact();
    Future<void>.delayed(const Duration(milliseconds: 90), () {
      HapticFeedback.mediumImpact();
    });
  }

  /// Rewind / deshacer.
  static void rewind() => HapticFeedback.selectionClick();
}
