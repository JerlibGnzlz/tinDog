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
      final fieldErrors = _fieldErrorsFromValidationList(message);
      return ApiException(
        _summaryFromFieldErrors(fieldErrors) ??
            message.map((e) => _translateMessage(e.toString())).join('\n'),
        fieldErrors: fieldErrors,
      );
    }

    if (message is String) {
      final translated = _translateMessage(message);
      return ApiException(
        translated,
        fieldErrors: _fieldErrorsForMessage(status, message, translated),
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
    'Sesión inválida. Vuelve a iniciar sesión.':
        'Sesión inválida. Vuelve a iniciar sesión.',
  };
  return translations[message] ?? message;
}

String? _summaryFromFieldErrors(Map<String, String>? fieldErrors) {
  if (fieldErrors == null || fieldErrors.isEmpty) return null;
  if (fieldErrors.length == 1) return fieldErrors.values.first;
  return 'Revisa los campos marcados';
}

Map<String, String>? _fieldErrorsForMessage(
  int? status,
  String rawMessage,
  String translated,
) {
  if (rawMessage == 'Email already registered') {
    return {'email': translated};
  }
  if (status == 401 || rawMessage == 'Invalid credentials') {
    return {'password': translated};
  }
  return null;
}

Map<String, String>? _fieldErrorsFromValidationList(List<dynamic> messages) {
  final errors = <String, String>{};

  for (final item in messages) {
    final text = item.toString();
    final lower = text.toLowerCase();

    if (lower.contains('email')) {
      errors['email'] = _translateValidation(text);
    } else if (lower.contains('password')) {
      errors['password'] = _translateValidation(text);
    }
  }

  return errors.isEmpty ? null : errors;
}

String _translateValidation(String message) {
  final lower = message.toLowerCase();
  if (lower.contains('email must be an email')) {
    return 'Ingresa un email válido';
  }
  if (lower.contains('password must be longer') ||
      lower.contains('password must be at least')) {
    return 'Usa al menos 8 caracteres';
  }
  if (lower.contains('email should not be empty') ||
      lower.contains('email must be a string')) {
    return 'El email es requerido';
  }
  if (lower.contains('password should not be empty') ||
      lower.contains('password must be a string')) {
    return 'La contraseña es requerida';
  }
  return _translateMessage(message);
}
