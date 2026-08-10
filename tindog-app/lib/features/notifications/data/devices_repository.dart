import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

final devicesRepositoryProvider = Provider<DevicesRepository>((ref) {
  return DevicesRepository(ref.watch(apiClientProvider));
});

class DevicesRepository {
  DevicesRepository(this._dio);

  final Dio _dio;

  Future<void> registerToken(String token, {String? platform}) async {
    await _dio.post<Map<String, dynamic>>(
      '/devices',
      data: {
        'token': token,
        'platform': platform ?? (Platform.isIOS ? 'ios' : 'android'),
      },
    );
  }

  Future<void> unregisterToken(String token) async {
    try {
      await _dio.delete<Map<String, dynamic>>(
        '/devices',
        data: {'token': token},
      );
    } catch (_) {
      // Best-effort al logout.
    }
  }

  /// `matchId` null = ya no está viendo un chat (omitir push de ese match).
  Future<void> setActiveChat(String? matchId) async {
    try {
      await _dio.put<Map<String, dynamic>>(
        '/devices/active-chat',
        data: {'matchId': matchId},
        // Al minimizar la OS puede matar el request; corto timeout.
        options: Options(
          sendTimeout: const Duration(seconds: 2),
          receiveTimeout: const Duration(seconds: 2),
        ),
      );
    } catch (_) {
      // Best-effort: Nest expira active-chat ~75s si el clear no llega.
    }
  }

  Future<void> setChatMuted({
    required String matchId,
    required bool muted,
  }) async {
    try {
      await _dio.put<Map<String, dynamic>>(
        '/devices/muted-chat',
        data: {'matchId': matchId, 'muted': muted},
      );
    } catch (_) {
      // Best-effort: Stream mute igual aplica en el cliente.
    }
  }
}
