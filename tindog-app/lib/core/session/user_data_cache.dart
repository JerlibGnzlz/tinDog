import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Contador para forzar recarga de perfil/mascota sin [ref.invalidate]
/// (evita CircularDependencyError desde [authSessionProvider]).
final userDataCacheGenerationProvider = StateProvider<int>((ref) => 0);

void bumpUserDataCache(Ref ref) {
  ref.read(userDataCacheGenerationProvider.notifier).update((n) => n + 1);
}
