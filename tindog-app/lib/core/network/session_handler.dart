import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/auth_provider.dart';
import 'api_error_mapper.dart';

bool isUnauthorizedError(Object error) {
  if (error is DioException) {
    return error.response?.statusCode == 401;
  }
  if (error is ApiException) {
    return error.message.contains('Sesión inválida') ||
        error.message.contains('no autorizada');
  }
  return false;
}

void handleSessionExpired(WidgetRef ref, BuildContext context, Object error) {
  if (!isUnauthorizedError(error)) return;

  ref.read(authSessionProvider.notifier).logout();
  if (context.mounted) {
    context.go('/login');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tu sesión expiró. Vuelve a iniciar sesión.'),
      ),
    );
  }
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
