import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import 'tindog_typing_label.dart';

/// Preview de la lista de chats: typing en vivo o último mensaje.
class TindogChatListSubtitle extends StatelessWidget {
  const TindogChatListSubtitle({
    super.key,
    required this.matchId,
    required this.fallbackPreview,
    this.otherUserId,
  });

  final String matchId;
  final String fallbackPreview;
  final String? otherUserId;

  @override
  Widget build(BuildContext context) {
    final client = StreamChat.maybeOf(context)?.client;
    if (client == null) {
      return _previewText(fallbackPreview);
    }

    final channel = client.channel('messaging', id: 'match-$matchId');
    final state = channel.state;
    if (state == null) {
      return _previewText(fallbackPreview);
    }

    final myId = client.state.currentUser?.id;

    return BetterStreamBuilder<Map<User, Event>>(
      stream: state.typingEventsStream,
      initialData: state.typingEvents,
      builder: (context, typing) {
        final someoneTyping = typing.keys.any((u) {
          if (u.id == myId) return false;
          if (otherUserId != null && otherUserId!.isNotEmpty) {
            return u.id == otherUserId;
          }
          return true;
        });

        if (someoneTyping) {
          return const TindogTypingLabel(
            style: TextStyle(
              color: AppColors.primaryDark,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          );
        }

        return _previewText(fallbackPreview);
      },
    );
  }

  Widget _previewText(String text) {
    final value = text.trim().isEmpty ? 'Nuevo match — ¡saludá!' : text;
    return Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
      ),
    );
  }
}
