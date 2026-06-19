import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/auth_provider.dart';

/// Cierra sesión y vuelve al welcome (flujo explícito de “Salir”).
Future<void> signOutToWelcome(WidgetRef ref, BuildContext context) async {
  ScaffoldMessenger.of(context).clearSnackBars();
  await ref.read(authSessionProvider.notifier).logout();
  if (context.mounted) context.go('/welcome');
}
