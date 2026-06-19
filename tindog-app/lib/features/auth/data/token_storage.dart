import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/app_constants.dart';

class TokenStorage {
  TokenStorage(this._storage);

  final FlutterSecureStorage _storage;
  String? _memoryToken;

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

  Future<void> deleteToken() async {
    _memoryToken = null;
    await _storage.delete(key: AppConstants.tokenKey);
  }
}
