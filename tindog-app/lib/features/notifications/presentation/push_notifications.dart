import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

  /// Match abierto en hilo (evita banner local si Nest aún manda FCM).
  String? _activeMatchId;

  final _local = FlutterLocalNotificationsPlugin();

  static const _chatChannel = AndroidNotificationChannel(
    'tindog_chat',
    'Chats tinDog',
    description: 'Mensajes de chat',
    importance: Importance.high,
  );

  static const _matchChannel = AndroidNotificationChannel(
    'tindog_matches',
    'Matches tinDog',
    description: 'Nuevos matches',
    importance: Importance.high,
  );

  void setActiveMatchId(String? matchId) {
    _activeMatchId = matchId?.trim().isEmpty == true ? null : matchId?.trim();
  }

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

    await _initLocalNotifications();

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

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
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

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _local.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    final android = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(_chatChannel);
    await android?.createNotificationChannel(_matchChannel);
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

  void _onForegroundMessage(RemoteMessage message) {
    final matchId = message.data['matchId']?.trim();
    if (matchId != null &&
        matchId.isNotEmpty &&
        matchId == _activeMatchId) {
      // Ya está en ese chat: no spamear banner.
      return;
    }

    final notification = message.notification;
    final title = notification?.title?.trim().isNotEmpty == true
        ? notification!.title!
        : _fallbackTitle(message.data);
    final body = notification?.body?.trim().isNotEmpty == true
        ? notification!.body!
        : (message.data['body']?.trim().isNotEmpty == true
            ? message.data['body']!
            : 'Abrí tinDog para verlo');

    unawaited(_showLocalNotification(
      title: title,
      body: body,
      data: message.data,
    ));
  }

  String _fallbackTitle(Map<String, dynamic> data) {
    final type = data['type']?.toString();
    if (type == 'match') return '¡Es un match! 🐾';
    return 'Nuevo mensaje';
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    final type = data['type']?.toString();
    final channel = type == 'match' ? _matchChannel : _chatChannel;
    final payload = jsonEncode({
      'matchId': data['matchId']?.toString() ?? '',
      'type': type ?? '',
    });

    await _local.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    try {
      final map = jsonDecode(payload) as Map<String, dynamic>;
      final matchId = map['matchId']?.toString().trim();
      if (matchId == null || matchId.isEmpty) return;
      onOpenMatch?.call(matchId);
    } catch (_) {
      // Payload inválido: ignorar.
    }
  }

  void _handleMessage(RemoteMessage message) {
    // match | message — ambos llevan matchId para deep link al chat
    final matchId = message.data['matchId']?.trim();
    if (matchId == null || matchId.isEmpty) return;
    onOpenMatch?.call(matchId);
  }
}
