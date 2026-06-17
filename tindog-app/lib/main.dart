import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

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

    return MaterialApp.router(
      title: 'tinDog',
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
