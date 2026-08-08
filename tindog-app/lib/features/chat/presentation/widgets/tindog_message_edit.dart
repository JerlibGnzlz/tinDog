import 'package:flutter/widgets.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

/// Ventana de edición estilo WhatsApp.
const kChatEditWindow = Duration(minutes: 15);

bool canEditChatMessage(Message message, {String? currentUserId}) {
  if (currentUserId == null || message.user?.id != currentUserId) {
    return false;
  }
  if (message.isDeleted || message.deletedAt != null) return false;

  final text = message.text?.trim() ?? '';
  if (text.isEmpty) return false;

  final hasPoll = message.poll != null;
  final hasGiphy = message.attachments.any(
    (a) => a.type == AttachmentType.giphy,
  );
  if (hasPoll || hasGiphy) return false;

  final age = DateTime.now().toUtc().difference(message.createdAt.toUtc());
  return age <= kChatEditWindow;
}

/// Quita "Editar" del menú si ya pasó la ventana.
List<Widget> filterMessageActionsForEditWindow(
  BuildContext context,
  List<StreamContextMenuAction<MessageAction>> defaultActions, {
  required String? currentUserId,
}) {
  final filtered = <StreamContextMenuAction<MessageAction>>[
    for (final action in defaultActions)
      if (action.props.value is! EditMessage ||
          canEditChatMessage(
            action.props.value!.message,
            currentUserId: currentUserId,
          ))
        action,
  ];
  return StreamContextMenuAction.partitioned(items: filtered);
}
