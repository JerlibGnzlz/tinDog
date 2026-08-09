import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
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

/// Leading del composer: adjuntos (+) + emojis.
class TindogComposerLeading extends StatelessWidget {
  const TindogComposerLeading({super.key, required this.props});

  final MessageComposerLeadingProps props;

  @override
  Widget build(BuildContext context) {
    // Durante grabación el leading ocupa ancho y hace overflow con
    // "Desliza para cancelar"; liberamos todo el espacio.
    if (props.isAudioRecordingFlowActive) {
      return const SizedBox.shrink();
    }

    final showExtras = props.controller.message.command == null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DefaultStreamMessageComposerLeading(props: props),
        if (showExtras)
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
      ],
    );
  }
}
