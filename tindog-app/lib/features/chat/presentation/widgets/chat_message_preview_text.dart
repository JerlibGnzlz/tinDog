import 'package:stream_chat_flutter/stream_chat_flutter.dart';

/// Texto de preview para lista de chats (Stream o fallback Nest).
String formatStreamMessagePreview(Message? message) {
  if (message == null) return '';
  if (message.isDeleted || message.deletedAt != null) {
    return 'Mensaje eliminado';
  }

  final text = message.text?.trim() ?? '';
  final attachments = message.attachments;
  if (attachments.isEmpty) {
    return text;
  }

  final types = attachments.map((a) => a.type?.toLowerCase() ?? '').toSet();
  final hasVoice = types.contains('voicerecording') ||
      types.contains('audio') ||
      attachments.any((a) => a.mimeType?.startsWith('audio/') == true);
  final hasVideo = types.contains('video') ||
      attachments.any((a) => a.mimeType?.startsWith('video/') == true);
  final hasImage = types.contains('image') ||
      types.contains('img') ||
      types.contains('giphy') ||
      attachments.any(
        (a) =>
            (a.imageUrl != null && a.imageUrl!.isNotEmpty) ||
            (a.thumbUrl != null && a.thumbUrl!.isNotEmpty),
      );
  final hasFile = types.contains('file');

  if (hasVoice) {
    return text.isEmpty ? '🎤 Mensaje de voz' : '🎤 $text';
  }
  if (hasVideo) {
    return text.isEmpty ? '🎬 Video' : '🎬 $text';
  }
  if (hasImage) {
    return text.isEmpty ? '📷 Foto' : '📷 $text';
  }
  if (hasFile) {
    return text.isEmpty ? '📎 Archivo' : '📎 $text';
  }
  return text.isEmpty ? 'Nuevo mensaje' : text;
}

String listPreviewWithDirection({
  required String body,
  required bool fromMe,
}) {
  final clean = body.trim();
  if (clean.isEmpty) return 'Nuevo match — ¡saludá!';
  return fromMe ? '← $clean' : clean;
}
