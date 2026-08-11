import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/devices_repository.dart';
import 'notification_preferences.dart';

const _chatChannel = AndroidNotificationChannel(
  'tindog_chat',
  'Chats tinDog',
  description: 'Mensajes de chat',
  importance: Importance.high,
  playSound: true,
  enableVibration: true,
);

const _matchChannel = AndroidNotificationChannel(
  'tindog_matches',
  'Matches tinDog',
  description: 'Nuevos matches',
  importance: Importance.high,
  playSound: true,
  enableVibration: true,
);

/// Muestra notificación local desde un [RemoteMessage] (foreground o background).
Future<void> displayRemotePush({
  required RemoteMessage message,
  bool playSound = true,
}) async {
  final data = message.data;
  final type = data['type']?.toString();
  final matchId = data['matchId']?.toString() ?? '';
  final title = (message.notification?.title ?? data['title'] ?? '')
      .toString()
      .trim();
  final body = (message.notification?.body ?? data['body'] ?? '')
      .toString()
      .trim();
  if (title.isEmpty && body.isEmpty) return;

  final channel = type == 'match' ? _matchChannel : _chatChannel;
  final plugin = FlutterLocalNotificationsPlugin();
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  await plugin.initialize(
    settings: const InitializationSettings(
      android: androidInit,
      iOS: DarwinInitializationSettings(),
    ),
  );
  final android = plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  await android?.createNotificationChannel(_chatChannel);
  await android?.createNotificationChannel(_matchChannel);

  final payload = jsonEncode({'matchId': matchId, 'type': type ?? ''});
  // Id estable por match + segundo: evita colisión y permite que cada mensaje suene.
  final idBase = matchId.hashCode & 0x3fffffff;
  final id = idBase ^ (DateTime.now().millisecondsSinceEpoch ~/ 1000);

  await plugin.show(
    id: id,
    title: title.isEmpty ? 'tinDog' : title,
    body: body.isEmpty ? 'Abrí tinDog para verlo' : body,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: Importance.high,
        priority: Priority.high,
        playSound: playSound,
        enableVibration: true,
        onlyAlertOnce: false,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: playSound,
      ),
    ),
    payload: payload,
  );
}

/// FCM en background/isolate (debe ser top-level).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  // Data-only en Android: hay que pintar la noti acá.
  try {
    await displayRemotePush(message: message, playSound: true);
  } catch (e) {
    if (kDebugMode) {
      debugPrint('background push display: $e');
    }
  }
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
    // iOS: presentación en foreground la hacemos nosotros con local notifs.
    await messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: false,
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
      // Ya está en ese chat: sin banner ni sonido.
      return;
    }

    final playSound = _ref.read(chatMessageSoundProvider);
    unawaited(displayRemotePush(message: message, playSound: playSound));
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
    final matchId = message.data['matchId']?.trim();
    if (matchId == null || matchId.isEmpty) return;
    onOpenMatch?.call(matchId);
  }
}
