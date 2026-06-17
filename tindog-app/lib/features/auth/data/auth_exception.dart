import 'package:dio/dio.dart';
import '../../../core/network/api_error_mapper.dart';

class AuthException implements Exception {
  AuthException(this.message, {this.fieldErrors});

  final String message;
  final Map<String, String>? fieldErrors;

  @override
  String toString() => message;
}

Never rethrowAuthError(Object error) {
  if (error is DioException) {
    final mapped = mapDioError(error);
    throw AuthException(mapped.message, fieldErrors: mapped.fieldErrors);
  }
  throw AuthException('Ocurrió un error inesperado. Intenta de nuevo.');
}
