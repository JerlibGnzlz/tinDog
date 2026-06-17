import 'package:dio/dio.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.fieldErrors});

  final String message;
  final Map<String, String>? fieldErrors;

  @override
  String toString() => message;
}

ApiException mapDioError(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionError:
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return ApiException(
        'No se pudo conectar con el servidor. '
        'Verifica que la API esté corriendo y la URL sea correcta.',
      );
    default:
      break;
  }

  final data = error.response?.data;
  if (data is Map<String, dynamic>) {
    final status = error.response?.statusCode;
    final message = data['message'];

    if (message is List) {
      return ApiException(
        message.map((e) => _translateMessage(e.toString())).join('\n'),
      );
    }

    if (message is String) {
      return ApiException(
        _translateMessage(message),
        fieldErrors: _fieldErrorsForStatus(status, message),
      );
    }
  }

  return ApiException('Ocurrió un error inesperado. Intenta de nuevo.');
}

String _translateMessage(String message) {
  const translations = {
    'Invalid credentials': 'Email o contraseña incorrectos',
    'Email already registered': 'Este email ya está registrado',
    'Unauthorized': 'Sesión no autorizada',
    'Sesión inválida. Vuelve a iniciar sesión.': 'Sesión inválida. Vuelve a iniciar sesión.',
  };
  return translations[message] ?? message;
}

Map<String, String>? _fieldErrorsForStatus(int? status, String message) {
  if (status == 401) {
    return {'password': 'Email o contraseña incorrectos'};
  }
  return null;
}
