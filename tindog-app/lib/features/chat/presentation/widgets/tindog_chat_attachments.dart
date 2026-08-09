import 'package:stream_chat_flutter/stream_chat_flutter.dart';

/// Normaliza attachments para que Stream muestre foto/video (y abra galería).
Message withVisibleMediaAttachments(Message message) {
  if (message.attachments.isEmpty) return message;

  var changed = false;
  final next = message.attachments.map((a) {
    final asImage = asVisibleImageAttachment(a);
    if (!identical(asImage, a)) {
      changed = true;
      return asImage;
    }
    final asVideo = asVisibleVideoAttachment(a);
    if (!identical(asVideo, a)) {
      changed = true;
      return asVideo;
    }
    return a;
  }).toList(growable: false);

  if (!changed) return message;
  return message.copyWith(attachments: next);
}

/// Alias histórico usado en el hilo.
Message withVisibleImageAttachments(Message message) =>
    withVisibleMediaAttachments(message);

Attachment asVisibleImageAttachment(Attachment attachment) {
  if (attachment.type == AttachmentType.image) {
    final url = _firstUrl(attachment);
    if (url != null &&
        (attachment.imageUrl == null || attachment.imageUrl!.trim().isEmpty)) {
      return attachment.copyWith(imageUrl: url);
    }
    return attachment;
  }

  if (!_looksLikeImage(attachment)) return attachment;

  final url = _firstUrl(attachment);
  return attachment.copyWith(
    type: AttachmentType.image,
    imageUrl: url ?? attachment.imageUrl,
  );
}

Attachment asVisibleVideoAttachment(Attachment attachment) {
  if (attachment.type == AttachmentType.video) {
    return attachment;
  }
  if (!_looksLikeVideo(attachment)) return attachment;

  final url = _firstUrl(attachment);
  return attachment.copyWith(
    type: AttachmentType.video,
    assetUrl: url ?? attachment.assetUrl,
    thumbUrl: attachment.thumbUrl ?? attachment.imageUrl,
  );
}

String? _firstUrl(Attachment a) {
  for (final candidate in [a.imageUrl, a.thumbUrl, a.assetUrl]) {
    final v = candidate?.trim();
    if (v != null && v.isNotEmpty) return v;
  }
  return null;
}

bool _looksLikeImage(Attachment a) {
  final mime = a.mimeType?.toLowerCase() ?? '';
  if (mime.startsWith('image/')) return true;

  final name = (a.title ?? a.file?.name ?? a.assetUrl ?? '').toLowerCase();
  return name.endsWith('.jpg') ||
      name.endsWith('.jpeg') ||
      name.endsWith('.png') ||
      name.endsWith('.gif') ||
      name.endsWith('.webp') ||
      name.endsWith('.heic') ||
      name.endsWith('.heif') ||
      name.endsWith('.bmp');
}

bool _looksLikeVideo(Attachment a) {
  final mime = a.mimeType?.toLowerCase() ?? '';
  if (mime.startsWith('video/')) return true;

  final name = (a.title ?? a.file?.name ?? a.assetUrl ?? '').toLowerCase();
  return name.endsWith('.mp4') ||
      name.endsWith('.mov') ||
      name.endsWith('.m4v') ||
      name.endsWith('.webm') ||
      name.endsWith('.mkv') ||
      name.endsWith('.3gp');
}
