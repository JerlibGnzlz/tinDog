import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/auth_provider.dart';
import 'api_error_mapper.dart';

/// Sin token local; evita llamadas API innecesarias en rutas protegidas.
class SessionRequiredException implements Exception {
  const SessionRequiredException();
}

bool isSessionError(Object error) {
  if (error is SessionRequiredException) return true;
  if (error is DioException) {
    return error.response?.statusCode == 401;
  }
  if (error is ApiException) {
    return error.message.contains('Sesión inválida') ||
        error.message.contains('no autorizada');
  }
  return false;
}

bool isUnauthorizedError(Object error) => isSessionError(error);

bool _handlingSessionExpiry = false;

void handleSessionExpired(WidgetRef ref, BuildContext context, Object error) {
  if (!isSessionError(error) || _handlingSessionExpiry) return;

  _handlingSessionExpiry = true;
  ref.read(authSessionProvider.notifier).logout().whenComplete(() {
    _handlingSessionExpiry = false;
  });

  if (!context.mounted) return;

  ScaffoldMessenger.of(context).clearSnackBars();
  context.go('/login');
}

String readableError(Object error) {
  if (error is DioException) {
    return mapDioError(error).message;
  }
  if (error is ApiException) {
    return error.message;
  }
  return error.toString();
}
