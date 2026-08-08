import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

enum ReportReason {
  spam,
  harassment,
  inappropriate,
  fake,
  other;

  String get apiValue => name;

  String get label => switch (this) {
        ReportReason.spam => 'Spam o publicidad',
        ReportReason.harassment => 'Acoso o insultos',
        ReportReason.inappropriate => 'Contenido inapropiado',
        ReportReason.fake => 'Perfil falso',
        ReportReason.other => 'Otro',
      };
}

final safetyRepositoryProvider = Provider<SafetyRepository>((ref) {
  return SafetyRepository(ref.watch(apiClientProvider));
});

class BlockedUser {
  const BlockedUser({
    required this.userId,
    required this.displayName,
    required this.blockedAt,
    this.photoUrl,
    this.petId,
  });

  final String userId;
  final String displayName;
  final String blockedAt;
  final String? photoUrl;
  final String? petId;

  factory BlockedUser.fromJson(Map<String, dynamic> json) {
    return BlockedUser(
      userId: json['userId'] as String,
      displayName: (json['displayName'] as String?)?.trim().isNotEmpty == true
          ? (json['displayName'] as String).trim()
          : 'Usuario',
      blockedAt: json['blockedAt'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      petId: json['petId'] as String?,
    );
  }
}

class SafetyRepository {
  SafetyRepository(this._dio);

  final Dio _dio;

  Future<void> blockUser(String userId) async {
    await _dio.post<Map<String, dynamic>>(
      '/safety/blocks',
      data: {'userId': userId},
    );
  }

  Future<void> unblockUser(String userId) async {
    await _dio.delete<Map<String, dynamic>>('/safety/blocks/$userId');
  }

  Future<List<BlockedUser>> listBlockedUsers() async {
    final response = await _dio.get<List<dynamic>>('/safety/blocks');
    final raw = response.data ?? const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(BlockedUser.fromJson)
        .toList(growable: false);
  }

  Future<void> reportUser({
    required String userId,
    required ReportReason reason,
    String? details,
    String? matchId,
    bool blockAlso = false,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/safety/reports',
      data: {
        'userId': userId,
        'reason': reason.apiValue,
        if (details?.trim().isNotEmpty == true) 'details': details!.trim(),
        'matchId': ?matchId,
        'blockAlso': blockAlso,
      },
    );
  }
}
