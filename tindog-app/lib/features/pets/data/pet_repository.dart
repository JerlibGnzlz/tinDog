import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import 'pet_model.dart';

final petRepositoryProvider = Provider<PetRepository>((ref) {
  return PetRepository(ref.watch(apiClientProvider));
});

class PetRepository {
  PetRepository(this._dio);

  final Dio _dio;

  Future<PetModel> getMyPet() async {
    final response = await _dio.get<Map<String, dynamic>>('/pets/me');
    return PetModel.fromJson(response.data!);
  }

  Future<PetModel> updateMyPet({String? name, String? photoUrl}) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/pets/me',
      data: {
        if (name != null) 'name': name,
        if (photoUrl != null) 'photoUrl': photoUrl,
      },
    );
    return PetModel.fromJson(response.data!);
  }
}
