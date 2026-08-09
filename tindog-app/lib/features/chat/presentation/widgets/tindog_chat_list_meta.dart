import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import 'chat_time_format.dart';

/// Hora del último mensaje (Stream en vivo, con fallback Nest).
class TindogChatListTimestamp extends StatelessWidget {
  const TindogChatListTimestamp({
    super.key,
    required this.matchId,
    this.fallback,
    this.emphasize = false,
  });

  final String matchId;
  final DateTime? fallback;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final client = StreamChat.maybeOf(context)?.client;
    if (client == null) {
      return _timeText(fallback);
    }

    final channel = client.channel('messaging', id: 'match-$matchId');
    final state = channel.state;
    if (state == null) {
      return _timeText(fallback);
    }

    return StreamBuilder<DateTime?>(
      stream: channel.lastMessageAtStream,
      initialData: channel.lastMessageAt ?? state.lastMessage?.createdAt,
      builder: (context, snapshot) {
        return _timeText(snapshot.data ?? fallback);
      },
    );
  }

  Widget _timeText(DateTime? at) {
    if (at == null) return const SizedBox.shrink();
    return Text(
      formatChatListTime(at),
      style: TextStyle(
        color: emphasize ? AppColors.primaryDark : AppColors.textSecondary,
        fontSize: 12,
        fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}

/// Campanita tachada si el canal del match está silenciado en Stream.
class TindogChatMutedIcon extends StatelessWidget {
  const TindogChatMutedIcon({super.key, required this.matchId});

  final String matchId;

  @override
  Widget build(BuildContext context) {
    final client = StreamChat.maybeOf(context)?.client;
    if (client == null) return const SizedBox.shrink();

    final channel = client.channel('messaging', id: 'match-$matchId');

    return BetterStreamBuilder<bool>(
      stream: channel.isMutedStream,
      initialData: channel.isMuted,
      builder: (context, muted) {
        if (!muted) return const SizedBox.shrink();
        return const Padding(
          padding: EdgeInsets.only(right: 4),
          child: Icon(
            Icons.notifications_off_outlined,
            size: 16,
            color: AppColors.textSecondary,
          ),
        );
      },
    );
  }
}
