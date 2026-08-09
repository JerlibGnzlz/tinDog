import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import 'chat_time_format.dart';

/// Avatar con punto de presencia Stream (verde = en línea).
class ChatPresenceAvatar extends StatelessWidget {
  const ChatPresenceAvatar({
    super.key,
    required this.photoUrl,
    this.streamUserId,
    this.radius = 28,
    this.onTap,
  });

  final String? photoUrl;
  final String? streamUserId;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.border,
      backgroundImage:
          photoUrl != null ? CachedNetworkImageProvider(photoUrl!) : null,
      child: photoUrl == null
          ? Icon(Icons.pets, color: AppColors.textSecondary, size: radius)
          : null,
    );

    final client = StreamChat.maybeOf(context)?.client;
    final state = client?.state;
    final userId = streamUserId;

    Widget content;
    if (state == null || userId == null || userId.isEmpty) {
      content = avatar;
    } else {
      content = BetterStreamBuilder<Map<String, User>>(
        stream: state.usersStream,
        initialData: state.users,
        builder: (context, users) {
          final online = users[userId]?.online ?? false;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              avatar,
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: radius * 0.45,
                  height: radius * 0.45,
                  decoration: BoxDecoration(
                    color: online ? AppColors.primary : AppColors.textSecondary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                ),
              ),
            ],
          );
        },
      );
    }

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: content,
      ),
    );
  }
}

/// Texto corto de presencia Stream: En línea / Últ. vez … / Desconectado.
class ChatPresenceLabel extends StatelessWidget {
  const ChatPresenceLabel({super.key, this.streamUserId});

  final String? streamUserId;

  @override
  Widget build(BuildContext context) {
    final state = StreamChat.maybeOf(context)?.client.state;
    final userId = streamUserId;
    if (userId == null || userId.isEmpty) {
      return const SizedBox.shrink();
    }

    if (state == null) {
      return Text(
        '…',
        style: TextStyle(
          color: AppColors.textSecondary.withValues(alpha: 0.7),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return BetterStreamBuilder<Map<String, User>>(
      stream: state.usersStream,
      initialData: state.users,
      builder: (context, users) {
        final user = users[userId];
        final online = user?.online ?? false;
        final label = formatPresenceLabel(
          online: online,
          lastActive: user?.lastActive,
        );
        return Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: online ? AppColors.primaryDark : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        );
      },
    );
  }
}
