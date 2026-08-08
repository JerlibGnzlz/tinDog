import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'tindog_message_edit.dart';

/// Menú largo-press con reacción ❤️ + acciones útiles (sin Flag/Mute/Block).
Future<void> showTindogMessageActions({
  required BuildContext context,
  required Message message,
  required void Function(Message message) onEdit,
  required void Function(Message message) onReply,
}) async {
  final channel = StreamChannel.of(context).channel;
  final currentUser = channel.client.state.currentUser;
  final me = currentUser?.id;

  final raw = StreamMessageActionsBuilder.buildActions(
    context: context,
    message: message,
    channel: channel,
    currentUser: currentUser,
  );

  final pruned = <StreamContextMenuAction<MessageAction>>[
    for (final action in raw)
      if (action.props.value is! FlagMessage &&
          action.props.value is! MuteUser &&
          action.props.value is! UnmuteUser &&
          action.props.value is! BlockUser &&
          action.props.value is! UnblockUser &&
          (action.props.value is! EditMessage ||
              canEditChatMessage(
                action.props.value!.message,
                currentUserId: me,
              )))
        action,
  ];

  final layout = StreamMessageLayout.of(context);
  final showHeart = channel.canSendReaction;
  final enforceUnique =
      StreamChatConfiguration.of(context).enforceUniqueReactions;

  final selected = await showStreamDialog<Object?>(
    context: context,
    useRootNavigator: false,
    builder: (_) => StreamChatConfiguration(
      data: StreamChatConfiguration.of(context),
      child: StreamMessageLayout(
        data: layout,
        child: StreamMessageActionsModal(
          message: message,
          showReactionPicker: showHeart,
          messageActions: StreamContextMenuAction.partitioned(items: pruned),
          messageWidget: StreamChannel.value(
            channel: channel,
            child: StreamMessageItem(
              key: const Key('TindogMessageActionsPreview'),
              message: message,
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ),
    ),
  );

  if (selected is! MessageAction) return;
  if (!context.mounted) return;

  switch (selected) {
    case EditMessage():
      onEdit(selected.message);
    case QuotedReply():
      onReply(selected.message);
    case CopyMessage():
      final text = selected.message.text?.trim();
      if (text != null && text.isNotEmpty) {
        await Clipboard.setData(ClipboardData(text: text));
      }
    case DeleteMessage():
      await channel.deleteMessage(selected.message);
    case HardDeleteMessage():
      await channel.deleteMessage(selected.message, hard: true);
    case PinMessage():
      await channel.pinMessage(selected.message);
    case UnpinMessage():
      await channel.unpinMessage(selected.message);
    case MarkUnread():
      await channel.markUnread(selected.message.id);
    case ResendMessage():
      await channel.retryMessage(selected.message);
    case SelectReaction(:final reaction):
      final own = [...?selected.message.ownReactions];
      final shouldDelete = own.any((r) => r.type == reaction.type);
      if (shouldDelete) {
        await channel.deleteReaction(selected.message, reaction);
      } else {
        await channel.sendReaction(
          selected.message,
          reaction,
          enforceUnique: enforceUnique,
        );
      }
    case ThreadReply():
    case FlagMessage():
    case MuteUser():
    case UnmuteUser():
    case BlockUser():
    case UnblockUser():
      break;
  }
}
