import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Banner compacto de red: «Sin conexión · Reintentar».
///
/// No incluye SafeArea: el padre decide el inset superior.
class TindogOfflineBanner extends StatelessWidget {
  const TindogOfflineBanner({
    super.key,
    required this.onRetry,
    this.message = 'Sin conexión',
    this.retryLabel = 'Reintentar',
  });

  final VoidCallback onRetry;
  final String message;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF3D4A2E),
      child: InkWell(
        onTap: onRetry,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
          child: Row(
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$message · $retryLabel',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  retryLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
