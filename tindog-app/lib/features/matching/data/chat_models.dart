import 'discover_candidate.dart';

enum ChatMessageType { text, image, video }

ChatMessageType chatMessageTypeFromJson(String? raw) {
  switch (raw) {
    case 'image':
      return ChatMessageType.image;
    case 'video':
      return ChatMessageType.video;
    default:
      return ChatMessageType.text;
  }
}

String chatMessageTypeToJson(ChatMessageType type) {
  switch (type) {
    case ChatMessageType.image:
      return 'image';
    case ChatMessageType.video:
      return 'video';
    case ChatMessageType.text:
      return 'text';
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.type,
    required this.body,
    required this.createdAt,
    required this.fromMe,
    required this.fromPetId,
    this.mediaUrl,
    this.mediaPublicId,
    this.thumbnailUrl,
    this.durationSec,
  });

  final String id;
  final ChatMessageType type;
  final String body;
  final DateTime createdAt;
  final bool fromMe;
  final String fromPetId;
  final String? mediaUrl;
  final String? mediaPublicId;
  final String? thumbnailUrl;
  final int? durationSec;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      type: chatMessageTypeFromJson(json['type'] as String?),
      body: json['body'] as String? ?? '',
      mediaUrl: json['mediaUrl'] as String?,
      mediaPublicId: json['mediaPublicId'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      durationSec: (json['durationSec'] as num?)?.toInt(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      fromMe: json['fromMe'] as bool? ?? false,
      fromPetId: json['fromPetId'] as String? ?? '',
    );
  }
}

class MatchThread {
  const MatchThread({
    required this.id,
    required this.matchedAt,
    required this.otherPet,
    required this.hasMessages,
    this.lastMessage,
  });

  final String id;
  final DateTime matchedAt;
  final DiscoverCandidate otherPet;
  final bool hasMessages;
  final ChatMessagePreview? lastMessage;

  factory MatchThread.fromJson(Map<String, dynamic> json) {
    final last = json['lastMessage'];
    return MatchThread(
      id: json['id'] as String,
      matchedAt: DateTime.tryParse(json['matchedAt'] as String? ?? '') ??
          DateTime.now(),
      otherPet: DiscoverCandidate.fromJson(
        json['otherPet'] as Map<String, dynamic>? ?? const {},
      ),
      hasMessages: json['hasMessages'] as bool? ?? false,
      lastMessage: last is Map<String, dynamic>
          ? ChatMessagePreview.fromJson(last)
          : null,
    );
  }
}

class ChatMessagePreview {
  const ChatMessagePreview({
    required this.id,
    required this.body,
    required this.createdAt,
    required this.fromMe,
    this.type = ChatMessageType.text,
  });

  final String id;
  final String body;
  final DateTime createdAt;
  final bool fromMe;
  final ChatMessageType type;

  factory ChatMessagePreview.fromJson(Map<String, dynamic> json) {
    return ChatMessagePreview(
      id: json['id'] as String,
      body: json['body'] as String? ?? '',
      type: chatMessageTypeFromJson(json['type'] as String?),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      fromMe: json['fromMe'] as bool? ?? false,
    );
  }

  String get previewText {
    var text = body.trim();
    if (text.isEmpty) {
      switch (type) {
        case ChatMessageType.image:
          text = '📷 Foto';
        case ChatMessageType.video:
          text = '🎬 Video';
        case ChatMessageType.text:
          text = 'Nuevo mensaje';
      }
    }
    return fromMe ? '← $text' : text;
  }
}
