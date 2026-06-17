import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEAEA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFC9C9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFD14343), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFB42318),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthHintBanner extends StatelessWidget {
  const AuthHintBanner({
    super.key,
    this.apiBaseUrl,
    this.onUseTestAccount,
  });

  final String? apiBaseUrl;
  final Future<void> Function()? onUseTestAccount;

  @override
  Widget build(BuildContext context) {
    final child = Text(
      [
        if (apiBaseUrl != null) 'API: $apiBaseUrl',
        onUseTestAccount == null
            ? 'Prueba con: lucas@tindog.test / password123'
            : 'Toca para iniciar sesión de prueba (lucas@tindog.test)',
      ].join('\n'),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: onUseTestAccount == null
          ? child
          : InkWell(
              onTap: () => onUseTestAccount!(),
              borderRadius: BorderRadius.circular(8),
              child: child,
            ),
    );
  }
}
