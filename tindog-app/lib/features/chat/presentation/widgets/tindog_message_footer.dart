import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import '../../../../core/theme/app_colors.dart';

/// Checks de envío: reloj → ✓ → ✓✓ → ✓✓ Visto (estilo WhatsApp / tinDog).
///
/// El footer va **fuera** de la burbuja (fondo crema): contraste oscuro.
class TindogSendingStatus extends StatelessWidget {
  const TindogSendingStatus({
    super.key,
    required this.message,
    this.size = 15,
  });

  final Message message;
  final double size;

  @override
  Widget build(BuildContext context) {
    final channel = StreamChannel.maybeOf(context)?.channel;

    return BetterStreamBuilder<List<Read>>(
      stream: channel?.state?.readStream,
      initialData: channel?.state?.read,
      builder: (context, data) {
        final isRead = data.readsOf(message: message).isNotEmpty;
        final isDelivered = data.deliveriesOf(message: message).isNotEmpty;

        // Enviado / entregado: salvia oscura. Visto: acento más marcado.
        const pending = AppColors.primaryDark;
        const seen = AppColors.accent;

        if (isRead) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.done_all_rounded, size: size, color: seen),
              const SizedBox(width: 3),
              const Text(
                'Visto',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: seen,
                  height: 1,
                ),
              ),
            ],
          );
        }
        if (isDelivered) {
          return Icon(Icons.done_all_rounded, size: size, color: pending);
        }
        if (message.state.isCompleted) {
          return Icon(Icons.done_rounded, size: size, color: pending);
        }
        if (message.state.isOutgoing) {
          return Icon(Icons.schedule_rounded, size: size, color: pending);
        }
        return const SizedBox.shrink();
      },
    );
  }
}

/// Footer con hora + edited + estado de envío/visto (fuera de la burbuja).
class TindogMessageFooter extends StatelessWidget {
  const TindogMessageFooter({super.key, required this.props});

  final StreamMessageFooterProps props;

  @override
  Widget build(BuildContext context) {
    final message = props.message;
    final me = StreamChat.of(context).currentUser?.id;
    final isMine = message.user?.id == me;

    return StreamMessageMetadata(
      style: StreamMessageMetadataStyle.from(
        timestampColor: AppColors.textPrimary,
        editedColor: AppColors.textSecondary,
        statusColor: AppColors.primaryDark,
        timestampTextStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
        statusTextStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          height: 1.1,
        ),
      ),
      timestamp: StreamTimestamp(
        date: message.createdAt.toLocal(),
        formatter: (context, date) => Jiffy.parseFromDateTime(date).jm,
      ),
      edited: message.messageTextUpdatedAt != null
          ? Text(context.translations.editedMessageLabel)
          : null,
      status: isMine ? TindogSendingStatus(message: message) : null,
    );
  }
}
