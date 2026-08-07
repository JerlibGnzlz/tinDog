import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

/// Avatar del remitente forzando nombre/foto tinDog (no snapshot Stream cruzado).
class TindogMessageLeading extends StatelessWidget {
  const TindogMessageLeading({
    super.key,
    required this.props,
    this.imageUrl,
    this.name,
  });

  final StreamMessageLeadingProps props;
  final String? imageUrl;
  final String? name;

  @override
  Widget build(BuildContext context) {
    final base = props.message.user;
    if (base == null) return const SizedBox.shrink();

    final resolvedName =
        (name != null && name!.trim().isNotEmpty) ? name!.trim() : base.name;
    final resolvedImage =
        (imageUrl != null && imageUrl!.trim().isNotEmpty)
            ? imageUrl!.trim()
            : base.image;

    final extra = Map<String, Object?>.from(base.extraData)
      ..['name'] = resolvedName
      ..remove('image');
    if (resolvedImage != null) {
      extra['image'] = resolvedImage;
    }

    final user = User(
      id: base.id,
      role: base.role,
      name: resolvedName,
      image: resolvedImage,
      online: base.online,
      extraData: extra,
    );

    Widget avatar = StreamUserAvatar(
      user: user,
      size: StreamAvatarSize.md,
      showOnlineIndicator: false,
    );
    if (props.onTap case final onTap?) {
      avatar = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: avatar,
      );
    }
    return avatar;
  }
}
