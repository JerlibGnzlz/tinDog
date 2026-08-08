import 'package:dio/dio.dart';
import '../../../core/network/api_error_mapper.dart';

/// Clasifica fallos al abrir / conectar chat Stream.
enum StreamChatFailureKind {
  offline,
  streamDown,
  matchGone,
  blocked,
  notConnected,
  unknown,
}

class StreamChatFailure {
  const StreamChatFailure({
    required this.kind,
    required this.title,
    required this.message,
    this.canRetry = true,
  });

  final StreamChatFailureKind kind;
  final String title;
  final String message;
  final bool canRetry;
}

StreamChatFailure classifyStreamChatError(Object error) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    final mapped = mapDioError(error).message;
    final lower = mapped.toLowerCase();

    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return const StreamChatFailure(
        kind: StreamChatFailureKind.offline,
        title: 'Sin conexión',
        message: 'Revisá tu internet e intentá de nuevo.',
      );
    }

    if (status == 503 ||
        lower.contains('stream chat no está configurado') ||
        lower.contains('no está configurado en el servidor')) {
      return const StreamChatFailure(
        kind: StreamChatFailureKind.streamDown,
        title: 'Chat no disponible',
        message:
            'El servicio de chat está en mantenimiento o no responde. '
            'Probá de nuevo en un momento.',
      );
    }

    if (status == 404 || lower.contains('match no encontrado')) {
      return const StreamChatFailure(
        kind: StreamChatFailureKind.matchGone,
        title: 'Este chat ya no existe',
        message: 'El match se eliminó o ya no está disponible.',
        canRetry: false,
      );
    }

    if (status == 400 &&
        (lower.contains('bloqueo') || lower.contains('interactuar'))) {
      return StreamChatFailure(
        kind: StreamChatFailureKind.blocked,
        title: 'No podés abrir este chat',
        message: mapped,
        canRetry: false,
      );
    }

    return StreamChatFailure(
      kind: StreamChatFailureKind.unknown,
      title: 'No se pudo abrir el chat',
      message: mapped,
    );
  }

  if (error is ApiException) {
    final mapped = error.message;
    final lower = mapped.toLowerCase();
    if (lower.contains('stream chat no está configurado') ||
        lower.contains('no está configurado en el servidor')) {
      return const StreamChatFailure(
        kind: StreamChatFailureKind.streamDown,
        title: 'Chat no disponible',
        message:
            'El servicio de chat está en mantenimiento o no responde. '
            'Probá de nuevo en un momento.',
      );
    }
    if (lower.contains('match no encontrado')) {
      return const StreamChatFailure(
        kind: StreamChatFailureKind.matchGone,
        title: 'Este chat ya no existe',
        message: 'El match se eliminó o ya no está disponible.',
        canRetry: false,
      );
    }
    if (lower.contains('bloqueo') || lower.contains('interactuar')) {
      return StreamChatFailure(
        kind: StreamChatFailureKind.blocked,
        title: 'No podés abrir este chat',
        message: mapped,
        canRetry: false,
      );
    }
    return StreamChatFailure(
      kind: StreamChatFailureKind.unknown,
      title: 'No se pudo abrir el chat',
      message: mapped,
    );
  }

  final text = error.toString();
  final lower = text.toLowerCase();
  if (lower.contains('stream no conectado') ||
      lower.contains('volvé a iniciar')) {
    return const StreamChatFailure(
      kind: StreamChatFailureKind.notConnected,
      title: 'Chat desconectado',
      message: 'Reconectamos el chat. Si sigue fallando, cerrá sesión y volvé a entrar.',
    );
  }

  // Stream SDK / genéricos: sacar "Exception: " / "Bad state: "
  var clean = text
      .replaceFirst(RegExp(r'^(Bad state|Exception|StateError):\s*'), '')
      .trim();
  if (clean.isEmpty) clean = 'Ocurrió un error inesperado.';

  return StreamChatFailure(
    kind: StreamChatFailureKind.unknown,
    title: 'No se pudo abrir el chat',
    message: clean,
  );
}

String streamChatErrorMessage(Object error) {
  final f = classifyStreamChatError(error);
  return '${f.title}. ${f.message}';
}

/// Mensaje corto para listas (Chats) cuando falla Stream.
String streamConnectionBannerMessage(Object? error) {
  if (error == null) {
    return 'Chat en tiempo real no conectado. Podés ver la lista; al abrir un chat intentamos reconectar.';
  }
  final f = classifyStreamChatError(error);
  if (f.kind == StreamChatFailureKind.offline) {
    return 'Sin conexión con el chat. Revisá internet y tocá Reconectar.';
  }
  if (f.kind == StreamChatFailureKind.streamDown) {
    return 'El chat no está disponible ahora. Tocá Reconectar en un momento.';
  }
  return 'No pudimos conectar el chat. Tocá Reconectar.';
}

// Re-export útil para callers que ya usan readableError en el mismo flujo.
String chatReadableError(Object error) => streamChatErrorMessage(error);
