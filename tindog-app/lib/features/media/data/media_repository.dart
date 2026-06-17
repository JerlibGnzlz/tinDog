import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/network/api_client.dart';

final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  return MediaRepository(ref.watch(apiClientProvider));
});

class MediaRepository {
  MediaRepository(this._dio);

  final Dio _dio;

  Future<String> uploadImage(XFile file) async {
    final bytes = await file.readAsBytes();
    final filename = file.name.isNotEmpty ? file.name : 'pet-photo.jpg';
    return _uploadBytes(bytes, filename);
  }

  Future<String> uploadImageBytes(
    Uint8List bytes, {
    String filename = 'pet-photo.jpg',
  }) {
    return _uploadBytes(bytes, filename);
  }

  Future<String> _uploadBytes(Uint8List bytes, String filename) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: DioMediaType.parse(_imageContentType(filename)),
      ),
    });

    final response = await _dio.post<Map<String, dynamic>>(
      '/media/upload',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    return response.data!['url'] as String;
  }

  String _imageContentType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }
}
