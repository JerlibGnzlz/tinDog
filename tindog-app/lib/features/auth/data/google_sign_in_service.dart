import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/constants/app_constants.dart';

/// Obtiene el idToken de Google (Android primero; iOS después).
///
/// Requiere [AppConstants.googleServerClientId] (OAuth **Web** client) para que
/// el backend pueda verificar el token.
class GoogleSignInService {
  GoogleSignInService();

  static bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    if (AppConstants.googleServerClientId.isEmpty) {
      throw StateError(
        'Falta GOOGLE_SERVER_CLIENT_ID en dart_defines '
        '(Client ID tipo Web de Google Cloud)',
      );
    }
    await GoogleSignIn.instance.initialize(
      serverClientId: AppConstants.googleServerClientId,
    );
    _initialized = true;
  }

  Future<String> getIdToken() async {
    if (kIsWeb) {
      throw StateError('Google Sign-In web no está habilitado aún');
    }
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      throw StateError('Google Sign-In solo en Android/iOS');
    }

    await _ensureInitialized();

    // Limpia sesión previa para forzar selector de cuenta.
    await GoogleSignIn.instance.signOut();

    try {
      final account = await GoogleSignIn.instance.authenticate(
        scopeHint: const ['email', 'profile'],
      );
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw StateError(
          'Google no devolvió idToken. Revisá SHA-1 y el Client ID Web.',
        );
      }
      return idToken;
    } on GoogleSignInException catch (e) {
      _initialized = false;
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw GoogleSignInCanceled();
      }
      throw GoogleSignInFailed(e);
    } catch (e) {
      _initialized = false;
      rethrow;
    }
  }
}

class GoogleSignInCanceled implements Exception {
  @override
  String toString() => 'Inicio con Google cancelado';
}

class GoogleSignInFailed implements Exception {
  GoogleSignInFailed(this.cause);

  final GoogleSignInException cause;

  String get userMessage {
    switch (cause.code) {
      case GoogleSignInExceptionCode.canceled:
        return 'Inicio con Google cancelado';
      case GoogleSignInExceptionCode.interrupted:
        return 'Se interrumpió el inicio con Google. Probá de nuevo.';
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
      case GoogleSignInExceptionCode.uiUnavailable:
        return 'En este emulador no hay Google Play Services. '
            'Usá un AVD con ícono de Play Store, o el celular físico.';
      case GoogleSignInExceptionCode.userMismatch:
        return 'Hay otra cuenta de Google activa. Cerrá sesión y reintentá.';
      case GoogleSignInExceptionCode.unknownError:
        return 'No se pudo iniciar con Google. '
            'En emulador suele fallar: usá uno con Play Store o el celular.';
    }
  }

  @override
  String toString() =>
      'GoogleSignInFailed(${cause.code.name}: ${cause.description})';
}
