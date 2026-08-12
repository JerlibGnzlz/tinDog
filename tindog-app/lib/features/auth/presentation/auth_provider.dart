import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/session/user_data_cache.dart';
import '../../notifications/presentation/push_notifications.dart';
import '../../pets/data/pet_repository.dart';
import '../data/auth_exception.dart';
import '../data/auth_repository.dart';
import '../data/google_sign_in_service.dart';

class AuthFailure {
  const AuthFailure({required this.message, this.fieldErrors});

  final String message;
  final Map<String, String>? fieldErrors;
}

final authSessionProvider =
    AsyncNotifierProvider<AuthSessionNotifier, bool>(AuthSessionNotifier.new);

final authFailureProvider = StateProvider<AuthFailure?>((ref) => null);

final googleSignInServiceProvider = Provider<GoogleSignInService>((ref) {
  return GoogleSignInService();
});

/// `true` si falta el nombre de la mascota (onboarding obligatorio).
final needsPetOnboardingProvider = FutureProvider<bool>((ref) async {
  final loggedIn = await ref.watch(authSessionProvider.future);
  if (!loggedIn) return false;

  final repo = ref.read(authRepositoryProvider);
  final stored = await repo.readNeedsPetOnboarding();
  if (stored != null) return stored;

  try {
    final pet = await ref.read(petRepositoryProvider).getMyPet();
    final needs = (pet.name ?? '').trim().isEmpty;
    await repo.saveNeedsPetOnboarding(needs);
    return needs;
  } catch (_) {
    return false;
  }
});

class AuthSessionNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    return ref.read(authRepositoryProvider).hasSession();
  }

  void _clearUserDataCache() {
    bumpUserDataCache(ref);
  }

  Future<bool> login(String email, String password) async {
    ref.read(authFailureProvider.notifier).state = null;
    state = const AsyncLoading();
    try {
      await ref
          .read(authRepositoryProvider)
          .login(email: email, password: password);
      state = const AsyncData(true);
      _clearUserDataCache();
      await ref.read(pushNotificationsProvider).syncTokenIfLoggedIn();
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

  Future<bool> loginWithGoogle() async {
    ref.read(authFailureProvider.notifier).state = null;
    state = const AsyncLoading();
    try {
      final idToken =
          await ref.read(googleSignInServiceProvider).getIdToken();
      await ref.read(authRepositoryProvider).loginWithGoogle(idToken: idToken);
      state = const AsyncData(true);
      _clearUserDataCache();
      await ref.read(pushNotificationsProvider).syncTokenIfLoggedIn();
      return true;
    } on GoogleSignInCanceled {
      state = const AsyncData(false);
      return false;
    } on GoogleSignInFailed catch (e) {
      debugPrint('Google Sign-In: $e');
      ref.read(authFailureProvider.notifier).state = AuthFailure(
        message: e.userMessage,
      );
      state = const AsyncData(false);
      return false;
    } on AuthException catch (e) {
      ref.read(authFailureProvider.notifier).state = AuthFailure(
        message: e.message,
        fieldErrors: e.fieldErrors,
      );
      state = const AsyncData(false);
      return false;
    } on StateError catch (e) {
      ref.read(authFailureProvider.notifier).state = AuthFailure(
        message: e.message,
      );
      state = const AsyncData(false);
      return false;
    } catch (_) {
      ref.read(authFailureProvider.notifier).state = const AuthFailure(
        message: 'No se pudo iniciar con Google. Intenta de nuevo.',
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
      _clearUserDataCache();
      await ref.read(pushNotificationsProvider).syncTokenIfLoggedIn();
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
    ref.read(authFailureProvider.notifier).state = null;
    await ref.read(pushNotificationsProvider).clearTokenOnLogout();
    state = const AsyncData(false);
    await ref.read(authRepositoryProvider).logout();
    // No invalidar acá: needsPetOnboardingProvider ya escucha authSession.
    _clearUserDataCache();
  }
}
