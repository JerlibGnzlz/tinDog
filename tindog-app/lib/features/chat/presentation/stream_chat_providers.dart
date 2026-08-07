import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/chat_repository.dart';

/// Cliente Stream conectado mientras hay sesión JWT de tinDog.
final streamChatClientProvider =
    AsyncNotifierProvider<StreamChatClientNotifier, StreamChatClient?>(
  StreamChatClientNotifier.new,
);

class StreamChatClientNotifier extends AsyncNotifier<StreamChatClient?> {
  StreamChatClient? _client;

  @override
  Future<StreamChatClient?> build() async {
    ref.listen<AsyncValue<bool>>(authSessionProvider, (prev, next) {
      final loggedIn = next.valueOrNull ?? false;
      if (!loggedIn) {
        _disconnect();
        state = const AsyncData(null);
      } else if (prev?.valueOrNull == false) {
        ref.invalidateSelf();
      }
    });

    final loggedIn = await ref.watch(authSessionProvider.future);
    if (!loggedIn) return null;

    final creds = await ref.read(chatRepositoryProvider).fetchToken();
    final client = StreamChatClient(
      creds.apiKey,
      logLevel: kDebugMode ? Level.WARNING : Level.SEVERE,
    );

    await client.connectUser(
      User(
        id: creds.user.id,
        name: creds.user.name,
        image: creds.user.image,
      ),
      creds.token,
    );

    _client = client;
    ref.onDispose(_disconnect);
    return client;
  }

  Future<void> reconnect() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  void _disconnect() {
    final client = _client;
    _client = null;
    if (client != null) {
      client.disconnectUser().ignore();
    }
  }
}
