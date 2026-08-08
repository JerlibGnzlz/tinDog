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
}
