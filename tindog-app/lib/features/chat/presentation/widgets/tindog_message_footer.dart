import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import '../../../../core/theme/app_colors.dart';

/// Checks de envío: reloj → ✓ → ✓✓ → ✓✓ visto (estilo WhatsApp / tinDog).
class TindogSendingStatus extends StatelessWidget {
  const TindogSendingStatus({
    super.key,
    required this.message,
    this.size = 14,
    this.onOwnBubble = true,
  });

  final Message message;
  final double size;
  final bool onOwnBubble;

  @override
  Widget build(BuildContext context) {
    final channel = StreamChannel.maybeOf(context)?.channel;

    return BetterStreamBuilder<List<Read>>(
      stream: channel?.state?.readStream,
      initialData: channel?.state?.read,
      builder: (context, data) {
        final isRead = data.readsOf(message: message).isNotEmpty;
        final isDelivered = data.deliveriesOf(message: message).isNotEmpty;

        // Sobre burbuja salvia: verde oscuro (el blanco no contrasta).
        final muted = onOwnBubble
            ? AppColors.primaryDark.withValues(alpha: 0.75)
            : AppColors.textSecondary;
        final seen = onOwnBubble ? AppColors.primaryDark : AppColors.accent;

        if (isRead) {
          return Icon(Icons.done_all_rounded, size: size, color: seen);
        }
        if (isDelivered) {
          return Icon(Icons.done_all_rounded, size: size, color: muted);
        }
        if (message.state.isCompleted) {
          return Icon(Icons.done_rounded, size: size, color: muted);
        }
        if (message.state.isOutgoing) {
          return Icon(Icons.schedule_rounded, size: size, color: muted);
        }
        return const SizedBox.shrink();
      },
    );
  }
}

/// Footer con hora + edited + estado de envío/visto.
class TindogMessageFooter extends StatelessWidget {
  const TindogMessageFooter({super.key, required this.props});

  final StreamMessageFooterProps props;

  @override
  Widget build(BuildContext context) {
    final message = props.message;
    final me = StreamChat.of(context).currentUser?.id;
    final isMine = message.user?.id == me;

    return StreamMessageMetadata(
      timestamp: StreamTimestamp(
        date: message.createdAt.toLocal(),
        formatter: (context, date) => Jiffy.parseFromDateTime(date).jm,
      ),
      edited: message.messageTextUpdatedAt != null
          ? Text(context.translations.editedMessageLabel)
          : null,
      status: isMine
          ? TindogSendingStatus(message: message, onOwnBubble: true)
          : null,
    );
  }
}
