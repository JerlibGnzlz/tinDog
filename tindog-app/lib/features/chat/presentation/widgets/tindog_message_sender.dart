import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import '../../data/chat_repository.dart';
import '../../../matching/data/discover_candidate.dart';

/// Perfil de display para un mensaje (nombre + foto de la mascota tinDog).
({String name, String? image})? resolveSenderProfile({
  required String senderId,
  required String? currentUserId,
  DiscoverCandidate? otherPet,
  Map<String, StreamChatUserDto> membersById = const {},
}) {
  // 1) Perfil del remitente real según ensureChannel (fuente de verdad).
  final member = membersById[senderId];
  if (member != null &&
      member.image != null &&
      member.image!.trim().isNotEmpty) {
    return (name: member.name, image: member.image);
  }

  final isMe = currentUserId != null && senderId == currentUserId;
  // 2) Chat 1:1 entrante → interlocutor del match.
  if (!isMe && otherPet != null) {
    final photo =
        otherPet.photoUrls.isNotEmpty ? otherPet.photoUrls.first : null;
    return (
      name: otherPet.name,
      image: photo ?? member?.image,
    );
  }

  if (member != null) {
    return (name: member.name, image: member.image);
  }

  return null;
}

/// Reescribe [message.user] con nombre/foto tinDog (no el snapshot viejo de Stream).
Message resolveIncomingSender({
  required Message message,
  required User? currentUser,
  DiscoverCandidate? otherPet,
  User? liveSender,
  Map<String, StreamChatUserDto> membersById = const {},
}) {
  final sender = message.user;
  if (sender == null) return message;

  final profile = resolveSenderProfile(
    senderId: sender.id,
    currentUserId: currentUser?.id,
    otherPet: otherPet,
    membersById: membersById,
  );

  if (profile == null) {
    if (liveSender != null && liveSender.id == sender.id) {
      return message.copyWith(
        user: _userWithProfile(
          sender,
          name: liveSender.name,
          image: liveSender.image,
        ),
      );
    }
    return message;
  }

  return message.copyWith(
    user: _userWithProfile(
      sender,
      name: profile.name,
      image: profile.image,
    ),
  );
}

/// Nuevo [User] con extraData limpio — evita que `copyWith` deje la image vieja.
User _userWithProfile(User base, {required String name, String? image}) {
  final extra = Map<String, Object?>.from(base.extraData)
    ..['name'] = name
    ..remove('image');
  if (image != null && image.trim().isNotEmpty) {
    extra['image'] = image.trim();
  }
  return User(
    id: base.id,
    role: base.role,
    name: name,
    image: image,
    createdAt: base.createdAt,
    updatedAt: base.updatedAt,
    lastActive: base.lastActive,
    online: base.online,
    banned: base.banned,
    banExpires: base.banExpires,
    teams: base.teams,
    language: base.language,
    invisible: base.invisible,
    teamsRole: base.teamsRole,
    avgResponseTime: base.avgResponseTime,
    extraData: extra,
  );
}
