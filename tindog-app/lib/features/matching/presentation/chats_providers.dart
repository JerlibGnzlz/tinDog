import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import '../../../core/network/session_handler.dart';
import '../../chat/presentation/stream_chat_providers.dart';
import '../data/chat_models.dart';
import '../data/matching_repository.dart';

final matchesProvider = FutureProvider.autoDispose<List<MatchThread>>((ref) async {
  final threads = await ref.watch(matchingRepositoryProvider).listMatches();
  await _syncStreamPresence(ref, threads);
  return threads;
});

/// Pide a Stream el estado online de los dueños de los matches.
Future<void> _syncStreamPresence(
  Ref ref,
  List<MatchThread> threads,
) async {
  final client = ref.read(streamChatClientProvider).valueOrNull;
  if (client == null) return;

  final ids = threads
      .map((t) => t.otherPet.ownerUserId)
      .whereType<String>()
      .where((id) => id.isNotEmpty)
      .toSet()
      .toList(growable: false);
  if (ids.isEmpty) return;

  try {
    await client.queryUsers(
      filter: Filter.in_('id', ids),
      presence: true,
    );
  } catch (_) {
    // La lista sigue útil sin presencia.
  }
}

final chatMessagesProvider = FutureProvider.autoDispose
    .family<List<ChatMessage>, String>((ref, matchId) {
  return ref.watch(matchingRepositoryProvider).listMessages(matchId);
});

String chatErrorMessage(Object error) => readableError(error);
