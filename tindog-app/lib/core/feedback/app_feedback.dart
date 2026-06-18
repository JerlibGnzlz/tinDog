import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'app_haptics.dart';

void showTindogSuccessSnackBar(BuildContext context, String message) {
  AppHaptics.success();
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22)
                .animate()
                .scale(
                  begin: const Offset(0.4, 0.4),
                  end: const Offset(1, 1),
                  duration: 350.ms,
                  curve: Curves.elasticOut,
                ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}

void showTindogInfoSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

void showTindogErrorSnackBar(BuildContext context, String message) {
  AppHaptics.error();
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
