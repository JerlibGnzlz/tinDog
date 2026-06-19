import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import 'profile_model.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(apiClientProvider));
});

class ProfileRepository {
  ProfileRepository(this._dio);

  final Dio _dio;

  Future<ProfileModel> getMyProfile() async {
    final response = await _dio.get<Map<String, dynamic>>('/profiles/me');
    return ProfileModel.fromJson(response.data!);
  }

  Future<ProfileModel> updateMyProfile({
    String? name,
    String? bio,
    String? avatarUrl,
    String? location,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/profiles/me',
      data: {
        'name': ?name,
        'bio': ?bio,
        'avatarUrl': ?avatarUrl,
        'location': ?location,
      },
    );
    return ProfileModel.fromJson(response.data!);
  }
}
