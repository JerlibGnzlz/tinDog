import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_exception.dart';
import '../data/auth_repository.dart';

class AuthFailure {
  const AuthFailure({required this.message, this.fieldErrors});

  final String message;
  final Map<String, String>? fieldErrors;
}

final authSessionProvider =
    AsyncNotifierProvider<AuthSessionNotifier, bool>(AuthSessionNotifier.new);

final authFailureProvider = StateProvider<AuthFailure?>((ref) => null);

class AuthSessionNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    return ref.read(authRepositoryProvider).hasSession();
  }

  Future<bool> login(String email, String password) async {
    ref.read(authFailureProvider.notifier).state = null;
    state = const AsyncLoading();
    try {
      await ref
          .read(authRepositoryProvider)
          .login(email: email, password: password);
      state = const AsyncData(true);
      return true;
    } on AuthException catch (e) {
      ref.read(authFailureProvider.notifier).state = AuthFailure(
        message: e.message,
        fieldErrors: e.fieldErrors,
      );
      state = const AsyncData(false);
      return false;
    } catch (_) {
      ref.read(authFailureProvider.notifier).state = const AuthFailure(
        message: 'Ocurrió un error inesperado. Intenta de nuevo.',
      );
      state = const AsyncData(false);
      return false;
    }
  }

  Future<bool> register(String email, String password) async {
    ref.read(authFailureProvider.notifier).state = null;
    state = const AsyncLoading();
    try {
      await ref
          .read(authRepositoryProvider)
          .register(email: email, password: password);
      state = const AsyncData(true);
      return true;
    } on AuthException catch (e) {
      ref.read(authFailureProvider.notifier).state = AuthFailure(
        message: e.message,
        fieldErrors: e.fieldErrors,
      );
      state = const AsyncData(false);
      return false;
    } catch (_) {
      ref.read(authFailureProvider.notifier).state = const AuthFailure(
        message: 'Ocurrió un error inesperado. Intenta de nuevo.',
      );
      state = const AsyncData(false);
      return false;
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    ref.read(authFailureProvider.notifier).state = null;
    state = const AsyncData(false);
  }
}
