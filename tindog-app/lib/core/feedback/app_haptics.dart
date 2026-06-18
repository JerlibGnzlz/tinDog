import 'package:flutter/services.dart';

abstract final class AppHaptics {
  static void light() => HapticFeedback.lightImpact();

  static void success() => HapticFeedback.mediumImpact();

  static void error() => HapticFeedback.heavyImpact();
}
