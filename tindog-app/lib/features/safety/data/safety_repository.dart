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
