import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stream_chat_localizations/stream_chat_localizations.dart';
import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/tindog_scroll_behavior.dart';
import 'features/chat/presentation/stream_chat_providers.dart';
import 'features/chat/presentation/tindog_stream_theme.dart';

void main() {
  if (kDebugMode) {
    debugPrint('tinDog API: ${AppConstants.apiBaseUrl}');
  }
  runApp(const ProviderScope(child: TinDogApp()));
}

class TinDogApp extends ConsumerWidget {
  const TinDogApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final streamClient = ref.watch(streamChatClientProvider).valueOrNull;

    return MaterialApp.router(
      title: 'tinDog',
      theme: AppTheme.light,
      scrollBehavior: const TindogScrollBehavior(),
      // Chat Stream + Material en español.
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
