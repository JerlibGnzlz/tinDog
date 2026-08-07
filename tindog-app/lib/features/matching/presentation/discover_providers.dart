import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/session_handler.dart';
import '../data/discover_candidate.dart';
import '../data/matching_repository.dart';

enum DiscoverSwipeDecision { like, pass }

class DiscoverDeckState {
  const DiscoverDeckState({
    required this.remaining,
    this.isLoading = false,
    this.errorMessage,
    this.lastDecision,
    this.lastCandidateId,
    this.lastMatched = false,
  });

  final List<DiscoverCandidate> remaining;
  final bool isLoading;
  final String? errorMessage;
  final DiscoverSwipeDecision? lastDecision;
  final String? lastCandidateId;
  final bool lastMatched;

  DiscoverCandidate? get current =>
      remaining.isEmpty ? null : remaining.first;

  bool get isEmpty => remaining.isEmpty && !isLoading;
}

class DiscoverDeckNotifier extends StateNotifier<DiscoverDeckState> {
  DiscoverDeckNotifier(this._repo)
      : super(const DiscoverDeckState(remaining: [], isLoading: true)) {
    reload();
  }

  final MatchingRepository _repo;

  Future<void> reload() async {
    state = DiscoverDeckState(
      remaining: state.remaining,
      isLoading: true,
      errorMessage: null,
    );
    try {
      final candidates = await _repo.discover();
      state = DiscoverDeckState(remaining: candidates);
    } catch (e) {
      state = DiscoverDeckState(
        remaining: const [],
        errorMessage: readableError(e),
      );
    }
  }

  Future<void> decide(DiscoverSwipeDecision decision) async {
    final current = state.current;
    if (current == null || state.isLoading) return;

    final rest = state.remaining.skip(1).toList(growable: false);

    // Optimistic UI: avanzar ya; si falla la API, recargar.
    state = DiscoverDeckState(
      remaining: rest,
      lastDecision: decision,
      lastCandidateId: current.id,
      lastMatched: false,
    );

    try {
      if (decision == DiscoverSwipeDecision.like) {
        final result = await _repo.like(current.id);
        if (result.matched) {
          state = DiscoverDeckState(
            remaining: state.remaining,
            lastDecision: decision,
            lastCandidateId: current.id,
            lastMatched: true,
          );
        }
      } else {
        await _repo.pass(current.id);
      }
    } catch (_) {
      await reload();
      rethrow;
    }
  }
}

final discoverDeckProvider =
    StateNotifierProvider<DiscoverDeckNotifier, DiscoverDeckState>((ref) {
  return DiscoverDeckNotifier(ref.watch(matchingRepositoryProvider));
});
