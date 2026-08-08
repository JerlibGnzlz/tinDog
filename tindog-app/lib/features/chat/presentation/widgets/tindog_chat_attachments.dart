import 'package:stream_chat_flutter/stream_chat_flutter.dart';

/// Convierte attachments de tipo `file` que son imágenes a `image`
/// para que Stream los renderice como foto (no como documento).
Message withVisibleImageAttachments(Message message) {
  if (message.attachments.isEmpty) return message;

  var changed = false;
  final next = message.attachments.map((a) {
    final fixed = asVisibleImageAttachment(a);
    if (!identical(fixed, a)) changed = true;
    return fixed;
  }).toList(growable: false);

  if (!changed) return message;
  return message.copyWith(attachments: next);
}

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
