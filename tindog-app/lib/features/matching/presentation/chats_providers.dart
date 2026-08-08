import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import '../../../core/network/session_handler.dart';
import '../../chat/presentation/stream_chat_providers.dart';
import '../data/chat_models.dart';
import '../data/matching_repository.dart';

/// Lista de matches + sync Stream (presencia mientras la lista está viva).
final matchesProvider =
    FutureProvider.autoDispose<List<MatchThread>>((ref) async {
  final threads = await ref.watch(matchingRepositoryProvider).listMatches();

  StreamChatClient? client;
  try {
    client = await ref.watch(streamChatClientProvider.future);
  } catch (_) {
    client = null;
  }

  if (client != null && threads.isNotEmpty) {
    await _syncStreamPresence(client, threads);
    final watched = await _watchMatchChannels(client, threads);
    ref.onDispose(() {
      unawaited(watched.cancel());
    });
  }

  return threads;
});

/// Mensajes no leídos (Stream). Vive mientras el shell lo observe.
final unreadChatsCountProvider = StreamProvider.autoDispose<int>((ref) async* {
  final client = await ref.watch(streamChatClientProvider.future);
  if (client == null) {
    yield 0;
    return;
  }

  yield client.state.totalUnreadCount;
  yield* client.state.totalUnreadCountStream;
});

/// Escucha mensajes Stream y refresca la lista (preview / «Tu turno») en vivo.
final chatsRealtimeInvalidatorProvider = Provider.autoDispose<void>((ref) {
  final client = ref.watch(streamChatClientProvider).valueOrNull;
  if (client == null) return;

  var disposed = false;
  Timer? debounce;
  final sub = client.on().listen((event) {
    final type = event.type;
    final isMessageEvent = type == EventType.messageNew ||
        type == EventType.messageUpdated ||
        type == EventType.messageDeleted ||
        type == EventType.notificationMessageNew;
    if (!isMessageEvent) return;

    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 400), () {
      if (!disposed) {
        ref.invalidate(matchesProvider);
      }
    });
  });

  ref.onDispose(() {
    disposed = true;
    debounce?.cancel();
    sub.cancel();
  });
});

Future<void> _syncStreamPresence(
  StreamChatClient client,
  List<MatchThread> threads,
) async {
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

class _ChannelWatchBundle {
  _ChannelWatchBundle(this._channels);

  final List<Channel> _channels;

  Future<void> cancel() async {
    for (final ch in _channels) {
      try {
        await ch.stopWatching();
      } catch (_) {}
    }
  }
}

Future<_ChannelWatchBundle> _watchMatchChannels(
  StreamChatClient client,
  List<MatchThread> threads,
) async {
  final channels = <Channel>[];
  for (final thread in threads) {
    try {
      final channel = client.channel(
        'messaging',
        id: 'match-${thread.id}',
      );
      await channel.watch(presence: true);
      channels.add(channel);
    } catch (_) {
      // Best-effort por canal.
    }
  }
  return _ChannelWatchBundle(channels);
}

final chatMessagesProvider = FutureProvider.autoDispose
    .family<List<ChatMessage>, String>((ref, matchId) {
  return ref.watch(matchingRepositoryProvider).listMessages(matchId);
});

String chatErrorMessage(Object error) => readableError(error);
