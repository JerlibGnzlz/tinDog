import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stream_chat_localizations/stream_chat_localizations.dart';
import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/tindog_scroll_behavior.dart';
import 'features/auth/presentation/auth_provider.dart';
import 'features/chat/presentation/stream_chat_providers.dart';
import 'features/chat/presentation/tindog_stream_theme.dart';
import 'features/notifications/presentation/push_notifications.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    debugPrint('tinDog API: ${AppConstants.apiBaseUrl}');
  }
  runApp(const ProviderScope(child: TinDogApp()));
}

class TinDogApp extends ConsumerStatefulWidget {
  const TinDogApp({super.key});

  @override
  ConsumerState<TinDogApp> createState() => _TinDogAppState();
}

class _TinDogAppState extends ConsumerState<TinDogApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _wirePush());
  }

  Future<void> _wirePush() async {
    final push = ref.read(pushNotificationsProvider);
    push.onOpenMatch = (matchId) {
      ref.read(routerProvider).go('/chats/$matchId');
    };

    final loggedIn = ref.read(authSessionProvider).valueOrNull ?? false;
    if (loggedIn) {
      await push.syncTokenIfLoggedIn();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final streamClient = ref.watch(streamChatClientProvider).valueOrNull;

    ref.listen<AsyncValue<bool>>(authSessionProvider, (prev, next) {
      final wasIn = prev?.valueOrNull ?? false;
      final isIn = next.valueOrNull ?? false;
      if (!wasIn && isIn) {
        unawaited(ref.read(pushNotificationsProvider).syncTokenIfLoggedIn());
      }
    });

    return MaterialApp.router(
      title: 'tinDog',
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      scrollBehavior: const TindogScrollBehavior(),
      locale: const Locale('es'),
      supportedLocales: const [
        Locale('es'),
        Locale('en'),
      ],
      localizationsDelegates: GlobalStreamChatLocalizations.delegates,
      routerConfig: router,
      builder: (context, child) {
        final content = child ?? const SizedBox.shrink();
        if (streamClient == null) return content;
        return wrapWithTindogStreamTheme(
          client: streamClient,
          child: content,
        );
      },
    );
  }
}
