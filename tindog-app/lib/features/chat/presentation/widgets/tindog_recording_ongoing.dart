import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

/// Centro del composer mientras se graba audio (hold + slide).
///
/// Copia el layout de [StreamMessageComposerRecordingOngoing] pero envuelve
/// "Desliza para cancelar" en [Flexible] para evitar overflow en pantallas
/// angostas / con el mic trailing.
class TindogRecordingOngoing extends StatelessWidget {
  const TindogRecordingOngoing({
    super.key,
    required this.audioRecorderController,
  });

  final StreamAudioRecorderController audioRecorderController;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.streamTextTheme;
    final colorScheme = context.streamColorScheme;
    final icons = context.streamIcons;

    return ExcludeSemantics(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 48,
              width: 48,
              alignment: Alignment.center,
              child: Icon(
                icons.voice,
                color: colorScheme.accentError,
                size: 20,
              ),
            ),
            ValueListenableBuilder(
              valueListenable: audioRecorderController,
              builder: (context, state, child) {
                final duration =
                    state is RecordStateRecording ? state.duration : Duration.zero;
                return Text(
                  duration.toMinutesAndSeconds(),
                  style: textTheme.captionEmphasis.copyWith(
                    color: colorScheme.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                );
              },
            ),
            SizedBox(width: context.streamSpacing.sm),
            Flexible(
              child: _GradientText(
                context.translations.slideToCancelLabel,
                style: textTheme.bodyDefault,
                gradient: LinearGradient(
                  colors: [colorScheme.textPrimary, colorScheme.textTertiary],
                ),
              ),
            ),
            SizedBox(width: context.streamSpacing.xxs),
            Icon(icons.chevronLeft, color: colorScheme.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Centro del composer: UI de grabación propia o el default de Stream.
class TindogComposerInputCenter extends StatelessWidget {
  const TindogComposerInputCenter({super.key, required this.props});

  final MessageComposerInputCenterProps props;

  @override
  Widget build(BuildContext context) {
    final recorder = props.audioRecorderController;
    final state = props.audioRecorderState;
    // Solo el hold (mantener mic). Si está locked/stopped, Stream muestra
    // cancelar/enviar; si interceptamos RecordStateRecording entero, el
    // candado deja la UI “pegada” sin botones.
    if (recorder != null && state is RecordStateRecordingHold) {
      return TindogRecordingOngoing(audioRecorderController: recorder);
    }
    return DefaultStreamMessageComposerInputCenter(props: props);
  }
}

class _GradientText extends StatelessWidget {
  const _GradientText(
    this.text, {
    required this.gradient,
    this.style,
  });

  final String text;
  final TextStyle? style;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(
        text,
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
      ),
    );
  }
}
