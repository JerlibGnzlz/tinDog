import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import '../../../../core/theme/app_colors.dart';

/// Subtítulo del header: no repite el nombre del perro.
/// - Alguien escribe → «está escribiendo…»
/// - Si no → «En línea» / «Desconectado»
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

    final myId = StreamChat.maybeOf(context)?.currentUser?.id;

    return BetterStreamBuilder<Map<User, Event>>(
      stream: channelState.typingEventsStream,
      initialData: channelState.typingEvents,
      builder: (context, typing) {
        final othersTyping = typing.keys
            .where((u) => u.id != myId)
            .toList(growable: false);

        if (othersTyping.isNotEmpty) {
          return Text(
            'está escribiendo…',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
            final online = other?.user?.online ?? false;
            return Text(
              online ? 'En línea' : 'Desconectado',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle.copyWith(
                color: online ? AppColors.primaryDark : AppColors.textSecondary,
                fontWeight: online ? FontWeight.w600 : FontWeight.w400,
              ),
            );
          },
        );
      },
    );
  }
}
