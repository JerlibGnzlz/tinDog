import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import 'chat_message_preview_text.dart';
import 'tindog_typing_label.dart';

/// Preview de la lista de chats: typing en vivo o último mensaje (incl. adjuntos).
class TindogChatListSubtitle extends StatelessWidget {
  const TindogChatListSubtitle({
    super.key,
    required this.matchId,
    required this.fallbackPreview,
    this.otherUserId,
    this.emphasize = false,
  });

  final String matchId;
  final String fallbackPreview;
  final String? otherUserId;
  final bool emphasize;

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

    return BetterStreamBuilder<List<Message>>(
      stream: state.messagesStream,
      initialData: state.messages,
      builder: (context, messages) {
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

            final last = _lastVisibleMessage(messages, myId);
            if (last == null) {
              return _previewText(fallbackPreview);
            }

            final body = formatStreamMessagePreview(last);
            final fromMe = myId != null && last.user?.id == myId;
            return _previewText(
              listPreviewWithDirection(body: body, fromMe: fromMe),
            );
          },
        );
      },
    );
  }

  Message? _lastVisibleMessage(List<Message> messages, String? myId) {
    for (var i = messages.length - 1; i >= 0; i--) {
      final m = messages[i];
      if (m.isDeleted || m.deletedAt != null) continue;
      if (m.shadowed && myId != null && m.user?.id != myId) continue;
      return m;
    }
    return null;
  }

  Widget _previewText(String text) {
    final value = text.trim().isEmpty ? 'Nuevo match — ¡saludá!' : text;
    return Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: emphasize ? AppColors.textPrimary : AppColors.textSecondary,
        fontSize: 13,
        fontWeight: emphasize ? FontWeight.w700 : FontWeight.w400,
      ),
    );
  }
}
