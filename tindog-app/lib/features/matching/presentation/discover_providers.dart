import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/session_handler.dart';
import '../data/discover_candidate.dart';
import '../data/matching_repository.dart';
import 'discover_filters.dart';

enum DiscoverSwipeDecision { like, pass }

class DiscoverDeckState {
  const DiscoverDeckState({
    required this.remaining,
    this.isLoading = false,
    this.errorMessage,
    this.lastDecision,
    this.lastCandidate,
    this.lastMatched = false,
    this.lastMatchId,
  });

  final List<DiscoverCandidate> remaining;
  final bool isLoading;
  final String? errorMessage;
  final DiscoverSwipeDecision? lastDecision;
  final DiscoverCandidate? lastCandidate;
  final bool lastMatched;
  final String? lastMatchId;

  DiscoverCandidate? get current =>
      remaining.isEmpty ? null : remaining.first;

  bool get isEmpty => remaining.isEmpty && !isLoading;

  bool get canRewind => lastCandidate != null && !isLoading;
}

final discoverFiltersProvider =
    StateProvider<DiscoverFilters>((ref) => const DiscoverFilters());

class DiscoverDeckNotifier extends StateNotifier<DiscoverDeckState> {
  DiscoverDeckNotifier(this._repo, this._ref)
      : super(const DiscoverDeckState(remaining: [], isLoading: true)) {
    reload();
    _ref.listen<DiscoverFilters>(discoverFiltersProvider, (prev, next) {
      if (prev != next) reload();
    });
  }

  final MatchingRepository _repo;
  final Ref _ref;

  Future<void> reload() async {
    state = DiscoverDeckState(
      remaining: state.remaining,
      isLoading: true,
      errorMessage: null,
    );
    try {
      final filters = _ref.read(discoverFiltersProvider);
      final candidates = await _repo.discover(
        mode: filters.mode.apiValue,
        breed: filters.breed,
        minAge: filters.minAge,
        maxAge: filters.maxAge,
        maxKm: filters.mode == DiscoverMode.near ? filters.maxKm : null,
      );
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

    state = DiscoverDeckState(
      remaining: rest,
      lastDecision: decision,
      lastCandidate: current,
      lastMatched: false,
    );

    try {
      if (decision == DiscoverSwipeDecision.like) {
        final result = await _repo.like(current.id);
        if (result.matched) {
          state = DiscoverDeckState(
            remaining: state.remaining,
            lastDecision: decision,
            lastCandidate: current,
            lastMatched: true,
            lastMatchId: result.matchId,
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

  Future<bool> rewind() async {
    final last = state.lastCandidate;
    if (last == null || state.isLoading) return false;

    final prevRemaining = state.remaining;
    final prevDecision = state.lastDecision;
    final prevMatched = state.lastMatched;
    final prevMatchId = state.lastMatchId;

    state = DiscoverDeckState(
      remaining: prevRemaining,
      isLoading: true,
      lastCandidate: last,
      lastDecision: prevDecision,
      lastMatched: prevMatched,
      lastMatchId: prevMatchId,
    );

    try {
      await _repo.rewind(last.id);
      final alreadyFront =
          prevRemaining.isNotEmpty && prevRemaining.first.id == last.id;
      state = DiscoverDeckState(
        remaining: alreadyFront ? prevRemaining : [last, ...prevRemaining],
      );
      return true;
    } catch (e) {
      state = DiscoverDeckState(
        remaining: prevRemaining,
        lastCandidate: last,
        lastDecision: prevDecision,
        lastMatched: prevMatched,
        lastMatchId: prevMatchId,
        errorMessage: readableError(e),
      );
      rethrow;
    }
  }
}

final discoverDeckProvider =
    StateNotifierProvider<DiscoverDeckNotifier, DiscoverDeckState>((ref) {
  return DiscoverDeckNotifier(ref.watch(matchingRepositoryProvider), ref);
});
