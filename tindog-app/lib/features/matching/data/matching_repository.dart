import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import 'chat_models.dart';
import 'discover_candidate.dart';

final matchingRepositoryProvider = Provider<MatchingRepository>((ref) {
  return MatchingRepository(ref.watch(apiClientProvider));
});

class MatchingRepository {
  MatchingRepository(this._dio);

  final Dio _dio;

  Future<List<DiscoverCandidate>> discover({
    int limit = 20,
    String mode = 'for_you',
    String? breed,
    int? minAge,
    int? maxAge,
    int? maxKm,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '/discover',
      queryParameters: {
        'limit': limit,
        'mode': mode,
        if (breed?.trim().isNotEmpty == true) 'breed': breed!.trim(),
        'minAge': ?minAge,
        'maxAge': ?maxAge,
        'maxKm': ?maxKm,
      },
    );
    final raw = response.data ?? const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(DiscoverCandidate.fromJson)
        .toList(growable: false);
  }

  Future<LikeResult> like(String toPetId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/likes',
      data: {'toPetId': toPetId},
    );
    return LikeResult.fromJson(response.data ?? const {});
  }

  Future<void> pass(String toPetId) async {
    await _dio.post<Map<String, dynamic>>(
      '/passes',
      data: {'toPetId': toPetId},
    );
  }

  Future<void> rewind(String toPetId) async {
    await _dio.post<Map<String, dynamic>>(
      '/rewind',
      data: {'toPetId': toPetId},
    );
  }

  Future<List<LikeListItem>> listSentLikes() async {
    final response = await _dio.get<List<dynamic>>('/likes/sent');
    return _mapLikeList(response.data);
  }

  Future<List<LikeListItem>> listReceivedLikes() async {
    final response = await _dio.get<List<dynamic>>('/likes/received');
    return _mapLikeList(response.data);
  }

  Future<LikesSummary> likesSummary() async {
    final response = await _dio.get<Map<String, dynamic>>('/likes/summary');
    return LikesSummary.fromJson(response.data ?? const {});
  }

  Future<List<MatchThread>> listMatches() async {
    final response = await _dio.get<List<dynamic>>('/matches');
    return (response.data ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(MatchThread.fromJson)
        .toList(growable: false);
  }

  Future<void> deleteMatch(String matchId) async {
    await _dio.delete<Map<String, dynamic>>('/matches/$matchId');
  }

  List<LikeListItem> _mapLikeList(List<dynamic>? raw) {
    return (raw ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(LikeListItem.fromJson)
        .toList(growable: false);
  }
}
