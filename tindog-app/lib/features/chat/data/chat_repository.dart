import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(apiClientProvider));
});

class StreamChatUserDto {
  const StreamChatUserDto({
    required this.id,
    required this.name,
    this.image,
  });

  final String id;
  final String name;
  final String? image;

  factory StreamChatUserDto.fromJson(Map<String, dynamic> json) {
    return StreamChatUserDto(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Usuario',
      image: json['image'] as String?,
    );
  }
}

class StreamChatTokenDto {
  const StreamChatTokenDto({
    required this.apiKey,
    required this.token,
    required this.user,
  });

  final String apiKey;
  final String token;
  final StreamChatUserDto user;

  factory StreamChatTokenDto.fromJson(Map<String, dynamic> json) {
    return StreamChatTokenDto(
      apiKey: json['apiKey'] as String,
      token: json['token'] as String,
      user: StreamChatUserDto.fromJson(
        json['user'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

class StreamChannelEnsureDto {
  const StreamChannelEnsureDto({
    required this.channelType,
    required this.channelId,
    this.other,
    this.members = const [],
  });

  final String channelType;
  final String channelId;
  final StreamChatUserDto? other;
  final List<StreamChatUserDto> members;

  factory StreamChannelEnsureDto.fromJson(Map<String, dynamic> json) {
    final otherRaw = json['other'];
    final membersRaw = json['members'] as List<dynamic>? ?? const [];
    return StreamChannelEnsureDto(
      channelType: json['channelType'] as String? ?? 'messaging',
      channelId: json['channelId'] as String,
      other: otherRaw is Map<String, dynamic>
          ? StreamChatUserDto.fromJson(otherRaw)
          : null,
      members: membersRaw
          .whereType<Map<String, dynamic>>()
          .map(StreamChatUserDto.fromJson)
          .toList(growable: false),
    );
  }
}

class ChatRepository {
  ChatRepository(this._dio);

  final Dio _dio;

  Future<StreamChatTokenDto> fetchToken() async {
    final response = await _dio.get<Map<String, dynamic>>('/chat/token');
    return StreamChatTokenDto.fromJson(response.data ?? const {});
  }

  Future<StreamChannelEnsureDto> ensureChannel(String matchId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/chat/channels/$matchId/ensure',
    );
    return StreamChannelEnsureDto.fromJson(response.data ?? const {});
  }
}
