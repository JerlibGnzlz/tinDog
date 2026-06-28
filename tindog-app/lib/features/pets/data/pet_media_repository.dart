import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import 'pet_media_model.dart';

final petMediaRepositoryProvider = Provider<PetMediaRepository>((ref) {
  return PetMediaRepository(ref.watch(apiClientProvider));
});

class PetMediaRepository {
  PetMediaRepository(this._dio);

  final Dio _dio;

  Future<List<PetMediaModel>> listMyPhotos() async {
    final response = await _dio.get<List<dynamic>>('/pets/me/media');
    return (response.data ?? [])
        .map((item) => PetMediaModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<PetMediaModel> addPhoto({
    required String url,
    required String publicId,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/pets/me/media',
      data: {'url': url, 'publicId': publicId},
    );
    return PetMediaModel.fromJson(response.data!);
  }

  Future<List<PetMediaModel>> setPrimary(String mediaId) async {
    final response = await _dio.patch<List<dynamic>>(
      '/pets/me/media/$mediaId/primary',
    );
    return (response.data ?? [])
        .map((item) => PetMediaModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<PetMediaModel>> deletePhoto(String mediaId) async {
    final response = await _dio.delete<List<dynamic>>(
      '/pets/me/media/$mediaId',
    );
    return (response.data ?? [])
        .map((item) => PetMediaModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<PetMediaModel>> listMyVideos() async {
    final response = await _dio.get<List<dynamic>>('/pets/me/videos');
    return (response.data ?? [])
        .map((item) => PetMediaModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<PetMediaModel> addVideo({
    required String url,
    required String publicId,
    int? durationSec,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/pets/me/videos',
      data: {
        'url': url,
        'publicId': publicId,
        'durationSec': ?durationSec,
      },
    );
    return PetMediaModel.fromJson(response.data!);
  }

  Future<List<PetMediaModel>> deleteVideo(String mediaId) async {
    final response = await _dio.delete<List<dynamic>>(
      '/pets/me/videos/$mediaId',
    );
    return (response.data ?? [])
        .map((item) => PetMediaModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
