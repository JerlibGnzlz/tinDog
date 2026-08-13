import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/auth_provider.dart';

/// Cierra sesión y vuelve al welcome (pantalla principal de auth).
Future<void> signOutToWelcome(WidgetRef ref, BuildContext context) async {
  final router = GoRouter.of(context);
  ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
  await ref.read(authSessionProvider.notifier).logout();
  router.go('/welcome');
}
