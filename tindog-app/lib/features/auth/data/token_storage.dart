import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/app_constants.dart';

class TokenStorage {
  TokenStorage(this._storage);

  final FlutterSecureStorage _storage;
  String? _memoryToken;
  bool? _memoryNeedsPetOnboarding;

  Future<void> saveToken(String token) async {
    _memoryToken = token;
    await _storage.write(key: AppConstants.tokenKey, value: token);
  }

  Future<String?> readToken() async {
    final cached = _memoryToken;
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    final stored = await _storage.read(key: AppConstants.tokenKey);
    _memoryToken = stored;
    return stored;
  }

  Future<void> saveNeedsPetOnboarding(bool value) async {
    _memoryNeedsPetOnboarding = value;
    await _storage.write(
      key: AppConstants.needsPetOnboardingKey,
      value: value ? '1' : '0',
    );
  }

  Future<bool?> readNeedsPetOnboarding() async {
    if (_memoryNeedsPetOnboarding != null) return _memoryNeedsPetOnboarding;
    final stored = await _storage.read(key: AppConstants.needsPetOnboardingKey);
    if (stored == null) return null;
    _memoryNeedsPetOnboarding = stored == '1';
    return _memoryNeedsPetOnboarding;
  }

  Future<void> clearNeedsPetOnboarding() async {
    _memoryNeedsPetOnboarding = null;
    await _storage.delete(key: AppConstants.needsPetOnboardingKey);
  }

  Future<void> deleteToken() async {
    _memoryToken = null;
    _memoryNeedsPetOnboarding = null;
    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.needsPetOnboardingKey);
  }
}
