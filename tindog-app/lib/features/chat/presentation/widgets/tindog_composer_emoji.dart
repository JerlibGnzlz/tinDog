import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import '../../../../core/feedback/app_feedback.dart';
import '../../../../core/theme/app_colors.dart';

/// Inserta un emoji en el cursor del composer.
void insertEmojiAtCursor(
  StreamMessageComposerController controller,
  String emoji,
) {
  final value = controller.textEditingValue;
  final selection = value.selection;
  final hasSelection = selection.isValid;
  final start = hasSelection ? selection.start : value.text.length;
  final end = hasSelection ? selection.end : value.text.length;
  final newText = value.text.replaceRange(start, end, emoji);
  final cursor = start + emoji.length;
  controller.textEditingValue = TextEditingValue(
    text: newText,
    selection: TextSelection.collapsed(offset: cursor),
  );
}

/// Abre el sheet de emojis comunes e inserta el elegido en el texto.
Future<void> pickAndInsertComposerEmoji({
  required BuildContext context,
  required StreamMessageComposerController controller,
}) async {
  final emoji = await StreamEmojiPickerSheet.show(
    context: context,
    backgroundColor: AppColors.card,
  );
  if (emoji == null || !context.mounted) return;
  insertEmojiAtCursor(controller, emoji.emoji);
}

/// Activa el comando `/giphy` si está habilitado en el canal Stream.
Future<void> activateGiphyCommand({
  required BuildContext context,
  required StreamMessageComposerController controller,
}) async {
  final channel = StreamChannel.maybeOf(context)?.channel;
  final commands = channel?.config?.commands ?? const <Command>[];
  final giphy = commands.firstWhereOrNull((c) => c.name == 'giphy');

  if (giphy == null) {
    showTindogInfoSnackBar(
      context,
      'GIF no disponible. En Stream Dashboard activá el comando giphy '
      'en el channel type messaging.',
    );
    return;
  }

  final reason = controller.validateCommand(giphy);
  if (reason != null) {
    showTindogInfoSnackBar(
      context,
      'No se puede abrir GIF ahora (cerrá editar/cita e intentá de nuevo).',
    );
    return;
  }

  controller.setCommand(giphy);
}

/// Leading del composer: adjuntos (+) + emojis + GIF.
class TindogComposerLeading extends StatelessWidget {
  const TindogComposerLeading({super.key, required this.props});

  final MessageComposerLeadingProps props;

  @override
  Widget build(BuildContext context) {
    final showExtras = !props.isAudioRecordingFlowActive &&
        props.controller.message.command == null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DefaultStreamMessageComposerLeading(props: props),
        if (showExtras) ...[
          IconButton(
            tooltip: 'Emojis',
            onPressed: props.isSlowModeActive
                ? null
                : () => pickAndInsertComposerEmoji(
                      context: context,
                      controller: props.controller,
                    ),
            icon: const Icon(
              Icons.emoji_emotions_outlined,
              color: AppColors.primaryDark,
            ),
          ),
          IconButton(
            tooltip: 'GIF',
            onPressed: props.isSlowModeActive
                ? null
                : () => activateGiphyCommand(
                      context: context,
                      controller: props.controller,
                    ),
            icon: const Icon(
              Icons.gif_box_outlined,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ],
    );
  }
}
