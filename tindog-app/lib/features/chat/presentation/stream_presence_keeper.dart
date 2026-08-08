import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import '../../matching/data/chat_models.dart';
import '../../matching/data/matching_repository.dart';
import 'stream_chat_providers.dart';

/// Mantiene presencia Stream desde que hay login + cliente conectado.
///
/// Sin esto, al invalidar la lista de chats se hacía `stopWatching` y un
/// usuario quedaba “Desconectado” aunque el otro sí lo veía en línea.
final streamPresenceKeeperProvider = Provider<void>((ref) {
  final client = ref.watch(streamChatClientProvider).valueOrNull;
  if (client == null) return;

  final keeper = _StreamPresenceKeeper(
    client: client,
    listMatches: () => ref.read(matchingRepositoryProvider).listMatches(),
  );
  keeper.start();
  ref.onDispose(keeper.dispose);
});

class _StreamPresenceKeeper {
  _StreamPresenceKeeper({
    required this.client,
    required this.listMatches,
  });

  final StreamChatClient client;
  final Future<List<MatchThread>> Function() listMatches;

  Timer? _timer;
  StreamSubscription<Event>? _events;
  bool _disposed = false;
  bool _running = false;

  void start() {
    if (_disposed) return;
    unawaited(_sync());
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      unawaited(_sync());
    });
    _events?.cancel();
    _events = client.on().listen((event) {
      if (event.type == EventType.connectionRecovered) {
        unawaited(_sync());
      }
    });
  }

  Future<void> _sync() async {
    if (_disposed || _running) return;
    _running = true;
    try {
      final threads = await listMatches();
      if (_disposed) return;

      final partnerIds = <String>{};
      final channelIds = <String>[];
      for (final thread in threads) {
        final ownerId = thread.otherPet.ownerUserId;
        if (ownerId != null && ownerId.isNotEmpty) {
          partnerIds.add(ownerId);
        }
        channelIds.add(thread.id);
      }

      final me = client.state.currentUser?.id;
      if (me != null && me.isNotEmpty) {
        partnerIds.add(me);
      }

      if (partnerIds.isNotEmpty) {
        await client.queryUsers(
          filter: Filter.in_('id', partnerIds.toList(growable: false)),
          presence: true,
        );
      }

      // Presencia vía watch (límite práctico ~10 canales).
      for (final matchId in channelIds.take(10)) {
        if (_disposed) return;
        try {
          final channel = client.channel('messaging', id: 'match-$matchId');
          await channel.watch(presence: true);
        } catch (_) {}
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Stream presence sync: $e');
      }
    } finally {
      _running = false;
    }
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _events?.cancel();
  }
}
