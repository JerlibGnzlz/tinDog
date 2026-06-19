import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/network/api_client.dart';

typedef UploadProgressCallback = void Function(int sent, int total);

final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  return MediaRepository(ref.watch(apiClientProvider));
});

class MediaRepository {
  MediaRepository(this._dio);

  final Dio _dio;

  Future<String> uploadImage(
    XFile file, {
    UploadProgressCallback? onProgress,
  }) async {
    final bytes = await file.readAsBytes();
    final filename = file.name.isNotEmpty ? file.name : 'pet-photo.jpg';
    return uploadImageBytes(bytes, filename: filename, onProgress: onProgress);
  }

  Future<String> uploadImageBytes(
    Uint8List bytes, {
    String filename = 'pet-photo.jpg',
    UploadProgressCallback? onProgress,
  }) {
    return _uploadBytes(bytes, filename, onProgress: onProgress);
  }

  Future<String> _uploadBytes(
    Uint8List bytes,
    String filename, {
    UploadProgressCallback? onProgress,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: _jpegFilename(filename),
        contentType: DioMediaType.parse('image/jpeg'),
      ),
    });

    final response = await _dio.post<Map<String, dynamic>>(
      '/media/upload',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
      onSendProgress: onProgress,
    );

    return response.data!['url'] as String;
  }

  String _jpegFilename(String filename) {
    final base = filename.contains('.')
        ? filename.substring(0, filename.lastIndexOf('.'))
        : filename;
    return '$base.jpg';
  }
}
