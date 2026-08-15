import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import 'tindog_recording_ongoing.dart';

/// Centro del composer: grabación hold, o texto con cursor que titila.
class TindogComposerInputCenter extends StatelessWidget {
  const TindogComposerInputCenter({super.key, required this.props});

  final MessageComposerInputCenterProps props;

  @override
  Widget build(BuildContext context) {
    final recorder = props.audioRecorderController;
    final state = props.audioRecorderState;
    if (recorder != null && state is RecordStateRecordingHold) {
      return TindogRecordingOngoing(audioRecorderController: recorder);
    }
    if (recorder != null &&
        (state is RecordStateRecordingLocked || state is RecordStateStopped)) {
      return DefaultStreamMessageComposerInputCenter(props: props);
    }

    final controller = props.controller;
    return StreamAccessibilityAutofocus(
      child: _TindogBlinkingComposerField(
        controller: controller.textFieldController,
        focusNode: props.focusNode,
        placeholder: props.placeholder,
        command: controller.message.command?.toUpperCase(),
        onDismissCommand: controller.clearCommand,
        textInputAction: props.textInputAction,
        keyboardType: props.keyboardType,
        textCapitalization: props.textCapitalization,
        autofocus: props.autofocus,
        autocorrect: props.autocorrect,
        enabled: !props.isSlowModeActive,
      ),
    );
  }
}

/// Campo de mensaje con cursor verde que titila (en Android el default no anima).
class _TindogBlinkingComposerField extends StatelessWidget {
  const _TindogBlinkingComposerField({
    required this.controller,
    required this.focusNode,
    required this.textCapitalization,
    required this.autofocus,
    required this.autocorrect,
    required this.enabled,
    this.placeholder,
    this.command,
    this.onDismissCommand,
    this.textInputAction,
    this.keyboardType,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? placeholder;
  final String? command;
  final VoidCallback? onDismissCommand;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final bool autofocus;
  final bool autocorrect;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final spacing = context.streamSpacing;
    final colors = context.streamColorScheme;
    final text = context.streamTextTheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 124),
      child: Padding(
        padding: EdgeInsets.all(spacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (command != null)
              StreamCommandChip(
                label: command!,
                onDismiss: onDismissCommand,
              ),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                enabled: enabled,
                textInputAction: textInputAction,
                keyboardType: keyboardType,
                textCapitalization: textCapitalization,
                autofocus: autofocus,
                autocorrect: autocorrect,
                style: text.bodyDefault.copyWith(color: colors.textPrimary),
                showCursor: true,
                cursorOpacityAnimates: true,
                cursorColor: AppColors.primaryDark,
                cursorWidth: 2.2,
                cursorRadius: const Radius.circular(1),
                maxLines: null,
                decoration: InputDecoration(
                  isCollapsed: true,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  hintText: placeholder,
                  hintStyle:
                      text.bodyDefault.copyWith(color: colors.textTertiary),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: spacing.xxs,
                    vertical: spacing.xxxs,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
