import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import '../../../../core/theme/app_colors.dart';

/// Contador de no leídos de un match (canal Stream `match-{id}`).
class TindogChatUnreadBadge extends StatelessWidget {
  const TindogChatUnreadBadge({super.key, required this.matchId});

  final String matchId;

  @override
  Widget build(BuildContext context) {
    final client = StreamChat.maybeOf(context)?.client;
    if (client == null) return const SizedBox.shrink();

    final channel = client.channel('messaging', id: 'match-$matchId');
    final state = channel.state;
    if (state == null) return const SizedBox.shrink();

    return BetterStreamBuilder<int>(
      stream: state.unreadCountStream,
      initialData: state.unreadCount,
      builder: (context, count) {
        if (count <= 0) return const SizedBox.shrink();
        return Container(
          constraints: const BoxConstraints(minWidth: 20),
          height: 20,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            count > 9 ? '9+' : '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        );
      },
    );
  }
}

/// True si el canal del match tiene mensajes sin leer.
class TindogChatHasUnread extends StatelessWidget {
  const TindogChatHasUnread({
    super.key,
    required this.matchId,
    required this.builder,
  });

  final String matchId;
  final Widget Function(BuildContext context, bool hasUnread) builder;

  @override
  Widget build(BuildContext context) {
    final client = StreamChat.maybeOf(context)?.client;
    if (client == null) return builder(context, false);

    final channel = client.channel('messaging', id: 'match-$matchId');
    final state = channel.state;
    if (state == null) return builder(context, false);

    return BetterStreamBuilder<int>(
      stream: state.unreadCountStream,
      initialData: state.unreadCount,
      builder: (context, count) => builder(context, count > 0),
    );
  }
}
