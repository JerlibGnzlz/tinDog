import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';

class TindogGradientProgressBar extends StatelessWidget {
  const TindogGradientProgressBar({
    super.key,
    required this.value,
    this.height = 8,
  });

  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: AppColors.border),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: clamped,
              child: const DecoratedBox(
                decoration: BoxDecoration(gradient: AppGradients.progress),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
