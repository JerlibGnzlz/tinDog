import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import 'tindog_typing_label.dart';

/// Subtítulo del header: no repite el nombre del perro.
/// - Alguien escribe → «está escribiendo…» animado
/// - Si no → «En línea» / «Desconectado» (presencia Stream)
class TindogChannelStatus extends StatelessWidget {
  const TindogChannelStatus({
    super.key,
    required this.channel,
    this.textStyle = const TextStyle(
      color: AppColors.textSecondary,
      fontSize: 12,
      height: 1.1,
    ),
  });

  final Channel channel;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    final channelState = channel.state;
    if (channelState == null) return const SizedBox.shrink();

    final client = StreamChat.maybeOf(context)?.client;
    final myId = client?.state.currentUser?.id;

    return BetterStreamBuilder<Map<User, Event>>(
      stream: channelState.typingEventsStream,
      initialData: channelState.typingEvents,
      builder: (context, typing) {
        final othersTyping = typing.keys
            .where((u) => u.id != myId)
            .toList(growable: false);

        if (othersTyping.isNotEmpty) {
          return TindogTypingLabel(
            style: textStyle.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w600,
            ),
          );
        }

        return BetterStreamBuilder<List<Member>>(
          stream: channelState.membersStream,
          initialData: channelState.members,
          builder: (context, members) {
            final other = members.firstWhereOrNull((m) => m.userId != myId);
            final otherUserId = other?.userId;
            if (otherUserId == null || otherUserId.isEmpty) {
              return Text(
                'Desconectado',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textStyle,
              );
            }

            final usersState = client?.state;
            if (usersState == null) {
              return _statusLabel(other?.user?.online ?? false);
            }

            // Solo presencia Stream (no watchers: pueden quedar “fantasma”).
            return BetterStreamBuilder<Map<String, User>>(
              stream: usersState.usersStream,
              initialData: usersState.users,
              builder: (context, users) {
                final online = users[otherUserId]?.online ?? false;
                return _statusLabel(online);
              },
            );
          },
        );
      },
    );
  }

  Widget _statusLabel(bool online) {
    return Text(
      online ? 'En línea' : 'Desconectado',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: textStyle.copyWith(
        color: online ? AppColors.primaryDark : AppColors.textSecondary,
        fontWeight: online ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }
}
