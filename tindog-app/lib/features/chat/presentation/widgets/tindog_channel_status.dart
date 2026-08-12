import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import 'chat_time_format.dart';
import 'tindog_typing_label.dart';

/// Subtítulo del header: dueño + presencia (sin repetir el nombre del perro).
/// - Alguien escribe → «está escribiendo…» animado
/// - Si no → «Con Hernán · En línea» / «Con Hernán · Últ. vez …»
class TindogChannelStatus extends StatelessWidget {
  const TindogChannelStatus({
    super.key,
    required this.channel,
    this.ownerName,
    this.textStyle = const TextStyle(
      color: AppColors.textSecondary,
      fontSize: 12,
      height: 1.1,
    ),
  });

  final Channel channel;
  /// Nombre del dueño (humano), si se conoce.
  final String? ownerName;
  final TextStyle textStyle;

  String? get _ownerLabel {
    final name = ownerName?.trim();
    if (name == null || name.isEmpty) return null;
    return 'Con $name';
  }

  @override
  Widget build(BuildContext context) {
    final channelState = channel.state;
    if (channelState == null) {
      final owner = _ownerLabel;
      if (owner == null) return const SizedBox.shrink();
      return Text(
        owner,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textStyle,
      );
    }

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
              return _composedLabel('Desconectado');
            }

            final usersState = client?.state;
            if (usersState == null) {
              return _statusLabel(
                online: other?.user?.online ?? false,
                lastActive: other?.user?.lastActive,
              );
            }

            return BetterStreamBuilder<Map<String, User>>(
              stream: usersState.usersStream,
              initialData: usersState.users,
              builder: (context, users) {
                final user = users[otherUserId];
                return _statusLabel(
                  online: user?.online ?? false,
                  lastActive: user?.lastActive,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _statusLabel({required bool online, DateTime? lastActive}) {
    final presence = formatPresenceLabel(
      online: online,
      lastActive: lastActive,
    );
    return _composedLabel(
      presence,
      emphasize: online,
    );
  }

  Widget _composedLabel(String presence, {bool emphasize = false}) {
    final owner = _ownerLabel;
    final text = owner == null ? presence : '$owner · $presence';
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: textStyle.copyWith(
        color: emphasize ? AppColors.primaryDark : AppColors.textSecondary,
        fontWeight: emphasize ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }
}
