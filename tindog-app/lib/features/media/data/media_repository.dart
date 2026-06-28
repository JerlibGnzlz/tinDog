import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/network/api_client.dart';

typedef UploadProgressCallback = void Function(int sent, int total);

final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  return MediaRepository(ref.watch(apiClientProvider));
});

class MediaUploadResult {
  const MediaUploadResult({
    required this.url,
    required this.publicId,
    this.durationSec,
  });

  final String url;
  final String publicId;
  final int? durationSec;
}

class MediaRepository {
  MediaRepository(this._dio);

  final Dio _dio;

  Future<MediaUploadResult> uploadImage(
    XFile file, {
    UploadProgressCallback? onProgress,
  }) async {
    final bytes = await file.readAsBytes();
    final filename = file.name.isNotEmpty ? file.name : 'pet-photo.jpg';
    return uploadImageBytes(bytes, filename: filename, onProgress: onProgress);
  }

  Future<MediaUploadResult> uploadImageBytes(
    Uint8List bytes, {
    String filename = 'pet-photo.jpg',
    UploadProgressCallback? onProgress,
  }) {
    return _uploadBytes(
      bytes,
      _jpegFilename(filename),
      endpoint: '/media/upload',
      contentType: 'image/jpeg',
      onProgress: onProgress,
    );
  }

  Future<MediaUploadResult> uploadVideo(
    XFile file, {
    UploadProgressCallback? onProgress,
  }) async {
    final bytes = await file.readAsBytes();
    final filename = file.name.isNotEmpty ? file.name : 'pet-video.mp4';
    return _uploadBytes(
      bytes,
      filename,
      endpoint: '/media/upload-video',
      contentType: _videoContentType(filename),
      onProgress: onProgress,
    );
  }

  Future<MediaUploadResult> _uploadBytes(
    Uint8List bytes,
    String filename, {
    required String endpoint,
    required String contentType,
    UploadProgressCallback? onProgress,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: DioMediaType.parse(contentType),
      ),
    });

    final response = await _dio.post<Map<String, dynamic>>(
      endpoint,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
      onSendProgress: onProgress,
    );

    return MediaUploadResult(
      url: response.data!['url'] as String,
      publicId: response.data!['publicId'] as String,
      durationSec: response.data!['durationSec'] as int?,
    );
  }

  String _jpegFilename(String filename) {
    final base = filename.contains('.')
        ? filename.substring(0, filename.lastIndexOf('.'))
        : filename;
    return '$base.jpg';
  }

  String _videoContentType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.mov')) return 'video/quicktime';
    if (lower.endsWith('.webm')) return 'video/webm';
    return 'video/mp4';
  }
}
