import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../stream_chat_errors.dart';

/// Panel de error al abrir un hilo Stream (reintento / volver).
class StreamChatErrorPanel extends StatelessWidget {
  const StreamChatErrorPanel({
    super.key,
    required this.error,
    required this.onRetry,
    this.onBack,
  });

  final Object error;
  final VoidCallback onRetry;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final failure = classifyStreamChatError(error);
    final icon = switch (failure.kind) {
      StreamChatFailureKind.offline => Icons.wifi_off_rounded,
      StreamChatFailureKind.streamDown => Icons.cloud_off_outlined,
      StreamChatFailureKind.matchGone => Icons.chat_bubble_outline_rounded,
      StreamChatFailureKind.blocked => Icons.block_rounded,
      StreamChatFailureKind.notConnected => Icons.link_off_rounded,
      StreamChatFailureKind.unknown => Icons.error_outline_rounded,
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.primaryDark),
            const SizedBox(height: 16),
            Text(
              failure.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              failure.message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.4,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            if (failure.canRetry)
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 44),
                ),
                onPressed: onRetry,
                child: const Text('Reintentar'),
              ),
            if (onBack != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: onBack,
                child: Text(
                  failure.canRetry ? 'Volver a Chats' : 'Ir a Chats',
                  style: const TextStyle(color: AppColors.primaryDark),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
