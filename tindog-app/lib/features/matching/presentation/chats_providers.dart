import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import '../../chat/presentation/stream_chat_errors.dart';
import '../../chat/presentation/stream_chat_providers.dart';
import '../data/chat_models.dart';
import '../data/matching_repository.dart';

/// IDs quitados en UI al instante (swipe/delete) hasta que refresca [matchesProvider].
/// Evita el error de Dismissible que sigue en el árbol tras confirmar.
final removedMatchIdsProvider = StateProvider<Set<String>>((ref) => {});

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

  if (client != null) {
    // Limpia no-leídos huérfanos (canales Stream que ya no están en matches).
    unawaited(_clearOrphanUnread(client, threads));

    if (threads.isNotEmpty) {
      await _syncStreamPresence(client, threads);
      // Watch con presencia, pero NO stopWatching al dispose: eso apagaba
      // “En línea” al refrescar la lista. La presencia la mantiene
      // streamPresenceKeeperProvider.
      await _watchMatchChannels(client, threads);
    }
  }

  return threads;
});

/// No leídos solo de matches conocidos (no usa totalUnreadCount global de Stream).
final unreadChatsCountProvider = StreamProvider.autoDispose<int>((ref) async* {
  final client = await ref.watch(streamChatClientProvider.future);
  if (client == null) {
    yield 0;
    return;
  }

  // Reacciona cuando cambia la lista de matches.
  ref.watch(matchesProvider);

  int sumForKnownMatches() {
    final threads = ref.read(matchesProvider).valueOrNull;
    if (threads == null || threads.isEmpty) return 0;
    var total = 0;
    for (final thread in threads) {
      final key = 'messaging:match-${thread.id}';
      final channel = client.state.channels[key];
      total += channel?.state?.unreadCount ?? 0;
    }
    return total;
  }

  yield sumForKnownMatches();
  yield* client.on().map((_) => sumForKnownMatches());
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
    // Canal borrado (bloqueo / unmatch del otro) → refrescar lista sola.
    final isChannelGone = type == EventType.channelDeleted ||
        type == EventType.notificationChannelDeleted ||
        type == EventType.notificationRemovedFromChannel;
    if (!isMessageEvent && !isChannelGone) return;

    debounce?.cancel();
    debounce = Timer(
      Duration(milliseconds: isChannelGone ? 80 : 400),
      () {
        if (!disposed) {
          ref.invalidate(matchesProvider);
        }
      },
    );
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

Future<void> _watchMatchChannels(
  StreamChatClient client,
  List<MatchThread> threads,
) async {
  for (final thread in threads) {
    final cid = 'messaging:match-${thread.id}';
    // Evita re-watch en cada refresh de la lista (quema cuota Stream).
    if (client.state.channels[cid]?.state != null) continue;
    try {
      final channel = client.channel(
        'messaging',
        id: 'match-${thread.id}',
      );
      await channel.watch(presence: true);
    } catch (_) {
      // Best-effort por canal.
    }
  }
}

/// Marca leídos canales messaging con unread que no corresponden a un match actual.
Future<void> _clearOrphanUnread(
  StreamChatClient client,
  List<MatchThread> threads,
) async {
  final me = client.state.currentUser?.id;
  if (me == null || me.isEmpty) return;

  final known = threads.map((t) => 'match-${t.id}').toSet();
  try {
    // Obligatorio: members $in — sin eso Stream responde 403 y gasta cuota.
    final channels = await client.queryChannelsOnline(
      filter: Filter.and([
        Filter.equal('type', 'messaging'),
        Filter.in_('members', [me]),
      ]),
      state: true,
      watch: false,
      paginationParams: const PaginationParams(limit: 30),
    );
    for (final channel in channels) {
      final id = channel.id;
      final unread = channel.state?.unreadCount ?? 0;
      if (id == null || unread <= 0) continue;
      if (known.contains(id)) continue;
      try {
        await channel.markRead();
      } catch (_) {}
    }
  } catch (_) {
    // Best-effort: el badge igual usa solo matches conocidos.
  }
}

String chatErrorMessage(Object error) => streamChatErrorMessage(error);
