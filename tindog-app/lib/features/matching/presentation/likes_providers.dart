import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/session_handler.dart';
import '../data/discover_candidate.dart';
import '../data/matching_repository.dart';

final likesSummaryProvider = FutureProvider.autoDispose<LikesSummary>((ref) {
  return ref.watch(matchingRepositoryProvider).likesSummary();
});

final sentLikesProvider =
    FutureProvider.autoDispose<List<LikeListItem>>((ref) {
  return ref.watch(matchingRepositoryProvider).listSentLikes();
});

final receivedLikesProvider =
    FutureProvider.autoDispose<List<LikeListItem>>((ref) {
  return ref.watch(matchingRepositoryProvider).listReceivedLikes();
});

String likesErrorMessage(Object error) => readableError(error);
