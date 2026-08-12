import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import 'auth_exception.dart';
import 'token_storage.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
  );
});

class AuthRepository {
  AuthRepository(this._dio, this._tokenStorage);

  final Dio _dio;
  final TokenStorage _tokenStorage;

  Future<void> register({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/register',
        data: {'email': email, 'password': password},
      );
      await _saveTokenFromResponse(response.data);
    } catch (e) {
      rethrowAuthError(e);
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      await _saveTokenFromResponse(response.data);
    } catch (e) {
      rethrowAuthError(e);
    }
  }

  Future<void> loginWithGoogle({required String idToken}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/google',
        data: {'idToken': idToken},
      );
      await _saveTokenFromResponse(response.data);
    } catch (e) {
      rethrowAuthError(e);
    }
  }

  Future<void> logout() => _tokenStorage.deleteToken();

  Future<bool> hasSession() async {
    final token = await _tokenStorage.readToken();
    return token != null && token.isNotEmpty;
  }

  Future<bool?> readNeedsPetOnboarding() =>
      _tokenStorage.readNeedsPetOnboarding();

  Future<void> saveNeedsPetOnboarding(bool value) =>
      _tokenStorage.saveNeedsPetOnboarding(value);

  Future<void> requestPasswordReset({required String email}) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/auth/forgot-password',
        data: {'email': email.trim().toLowerCase()},
      );
    } catch (e) {
      rethrowAuthError(e);
    }
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/auth/reset-password',
        data: {
          'email': email.trim().toLowerCase(),
          'code': code,
          'password': password,
        },
      );
    } catch (e) {
      rethrowAuthError(e);
    }
  }

  Future<void> _saveTokenFromResponse(Map<String, dynamic>? data) async {
    final token = data?['accessToken'] as String?;
    if (token == null || token.isEmpty) {
      throw Exception('Token no recibido del servidor');
    }
    await _tokenStorage.saveToken(token);
    // No reutilizar un flag viejo: si el API no manda el campo, se recuenta con /pets/me.
    await _tokenStorage.clearNeedsPetOnboarding();
    final needs = data?['needsPetOnboarding'];
    if (needs is bool) {
      await _tokenStorage.saveNeedsPetOnboarding(needs);
    }
  }
}
