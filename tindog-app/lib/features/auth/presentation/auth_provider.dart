import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';

final authSessionProvider =
    AsyncNotifierProvider<AuthSessionNotifier, bool>(AuthSessionNotifier.new);

class AuthSessionNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    return ref.read(authRepositoryProvider).hasSession();
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(authRepositoryProvider)
          .login(email: email, password: password);
      return true;
    });
  }

  Future<void> register(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(authRepositoryProvider)
          .register(email: email, password: password);
      return true;
    });
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(false);
  }
}
