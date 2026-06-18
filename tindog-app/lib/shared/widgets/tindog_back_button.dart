import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Botón atrás minimal: solo chevron, estilo Tinder/iOS.
class TindogBackButton extends StatelessWidget {
  const TindogBackButton({
    super.key,
    this.onPressed,
  });

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
      tooltip: 'Volver',
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
      ),
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
    );
  }
}
