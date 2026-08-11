import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/network/api_client.dart';

const _chatSoundKey = 'prefs_chat_message_sound';

/// Sonido al recibir mensajes (app en primer plano / banner local).
/// En segundo plano el SO + canal FCM siguen avisando; el usuario puede
/// silenciar el teléfono o un chat concreto.
final chatMessageSoundProvider =
    StateNotifierProvider<ChatMessageSoundNotifier, bool>((ref) {
  return ChatMessageSoundNotifier(ref.watch(secureStorageProvider));
});

class ChatMessageSoundNotifier extends StateNotifier<bool> {
  ChatMessageSoundNotifier(this._storage) : super(true) {
    _load();
  }

  final FlutterSecureStorage _storage;

  Future<void> _load() async {
    try {
      final raw = await _storage.read(key: _chatSoundKey);
      if (raw == null) return;
      state = raw != '0' && raw.toLowerCase() != 'false';
    } catch (_) {
      // Default: sonido on.
    }
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    try {
      await _storage.write(key: _chatSoundKey, value: enabled ? '1' : '0');
    } catch (_) {}
  }
}
