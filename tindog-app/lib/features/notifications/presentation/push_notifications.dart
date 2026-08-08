import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/devices_repository.dart';


/// Maneja FCM en background (debe ser top-level).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Solo asegurar Firebase; la UI se abre al tap vía getInitialMessage.
  try {
    await Firebase.initializeApp();
  } catch (_) {}
}

final pushNotificationsProvider = Provider<PushNotificationsService>((ref) {
  return PushNotificationsService(ref);
});

class PushNotificationsService {
  PushNotificationsService(this._ref);

  final Ref _ref;
  bool _initialized = false;
  String? _currentToken;
  void Function(String matchId)? onOpenMatch;

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    try {
      await Firebase.initializeApp();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Firebase.initializeApp: $e');
      }
      return;
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await messaging.requestPermission(alert: true, badge: true, sound: true);

    if (Platform.isAndroid) {
      await messaging.setAutoInitEnabled(true);
    }

    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      _handleMessage(initial);
    }

    messaging.onTokenRefresh.listen((token) {
      unawaited(_register(token));
    });

    _initialized = true;
  }

  Future<void> syncTokenIfLoggedIn() async {
    await ensureInitialized();
    if (!_initialized) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await _register(token);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FCM getToken: $e');
      }
    }
  }

  Future<void> clearTokenOnLogout() async {
    final token = _currentToken;
    _currentToken = null;
    if (token == null) return;
    await _ref.read(devicesRepositoryProvider).unregisterToken(token);
  }

  Future<void> _register(String token) async {
    _currentToken = token;
    try {
      await _ref.read(devicesRepositoryProvider).registerToken(token);
      if (kDebugMode) {
        debugPrint('FCM token registrado (${token.substring(0, 12)}…)');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FCM registerToken: $e');
      }
    }
  }

  void _handleMessage(RemoteMessage message) {
    final matchId = message.data['matchId']?.trim();
    if (matchId == null || matchId.isEmpty) return;
    onOpenMatch?.call(matchId);
  }
}
