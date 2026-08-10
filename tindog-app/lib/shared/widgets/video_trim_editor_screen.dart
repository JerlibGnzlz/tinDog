import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_trimmer/video_trimmer.dart';
import '../../core/theme/app_colors.dart';
import '../../features/pets/data/pet_media_model.dart';

/// Editor para elegir un tramo de hasta [maxLength] (default 30s).
///
/// Devuelve el [File] recortado, o `null` si cancela.
Future<File?> openVideoTrimEditor({
  required BuildContext context,
  required File videoFile,
  Duration maxLength = const Duration(seconds: maxVideoDurationSec),
}) async {
  // Si el video es más corto que el máximo + padding del TrimViewer,
  // no forzar maxLength (el package tira error).
  var effectiveMax = maxLength;
  try {
    final controller = VideoPlayerController.file(videoFile);
    await controller.initialize();
    final total = controller.value.duration;
    await controller.dispose();
    if (total <= maxLength) {
      effectiveMax = Duration.zero;
    }
  } catch (_) {
    // Seguir con maxLength por defecto.
  }

  if (!context.mounted) return null;
  return Navigator.of(context).push<File>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => VideoTrimEditorScreen(
        videoFile: videoFile,
        maxLength: effectiveMax,
        limitLabelSec: maxLength.inSeconds,
      ),
    ),
  );
}

class VideoTrimEditorScreen extends StatefulWidget {
  const VideoTrimEditorScreen({
    super.key,
    required this.videoFile,
    this.maxLength = const Duration(seconds: maxVideoDurationSec),
    this.limitLabelSec = maxVideoDurationSec,
  });

  final File videoFile;
  /// `Duration.zero` = sin tope de ventana (video ya corto).
  final Duration maxLength;
  final int limitLabelSec;

  @override
  State<VideoTrimEditorScreen> createState() => _VideoTrimEditorScreenState();
}

class _VideoTrimEditorScreenState extends State<VideoTrimEditorScreen> {
  final _trimmer = Trimmer();
  double _startValue = 0;
  double _endValue = 0;
  var _isPlaying = false;
  var _saving = false;
  var _ready = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _trimmer.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      await _trimmer.loadVideo(videoFile: widget.videoFile);
      if (!mounted) return;
      setState(() => _ready = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadError = 'No se pudo abrir el video');
    }
  }

  Future<void> _save() async {
    if (_saving || !_ready) return;
    final spanMs = (_endValue - _startValue).abs();
    if (spanMs < 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elegí un tramo un poco más largo')),
      );
      return;
    }
    final maxMs = widget.maxLength.inMilliseconds;
    if (maxMs > 0 && spanMs > maxMs + 250) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'El clip puede durar como máximo ${widget.limitLabelSec} s',
          ),
        ),
      );
      return;
    }
    if (maxMs <= 0 &&
        spanMs >
            const Duration(seconds: maxVideoDurationSec).inMilliseconds + 250) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'El clip puede durar como máximo $maxVideoDurationSec s',
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    await _trimmer.saveTrimmedVideo(
      startValue: _startValue,
      endValue: _endValue,
      onSave: (outputPath) {
        if (!mounted) return;
        setState(() => _saving = false);
        if (outputPath == null || outputPath.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo recortar el video')),
          );
          return;
        }
        Navigator.pop(context, File(outputPath));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hintMax = widget.limitLabelSec;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Recortar video',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
        ),
        actions: [
          TextButton(
            onPressed: (_saving || !_ready) ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Text(
                    'Usar clip',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: _loadError != null
          ? Center(
              child: Text(
                _loadError!,
                style: const TextStyle(color: Colors.white70),
              ),
            )
          : !_ready
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : Column(
                  children: [
                    if (_saving)
                      const LinearProgressIndicator(
                        color: AppColors.primary,
                        backgroundColor: Colors.white12,
                      ),
                    Expanded(
                      child: VideoViewer(trimmer: _trimmer),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                      child: TrimViewer(
                        trimmer: _trimmer,
                        viewerHeight: 56,
                        viewerWidth: MediaQuery.sizeOf(context).width - 24,
                        maxVideoLength: widget.maxLength,
                        durationStyle: DurationStyle.FORMAT_MM_SS,
                        editorProperties: TrimEditorProperties(
                          borderPaintColor: AppColors.primary,
                          circlePaintColor: AppColors.primaryDark,
                          borderWidth: 3,
                          borderRadius: 6,
                        ),
                        areaProperties: TrimAreaProperties.edgeBlur(
                          thumbnailQuality: 40,
                        ),
                        onChangeStart: (v) => _startValue = v,
                        onChangeEnd: (v) => _endValue = v,
                        onChangePlaybackState: (playing) {
                          if (mounted) setState(() => _isPlaying = playing);
                        },
                      ),
                    ),
                    IconButton(
                      onPressed: _saving
                          ? null
                          : () async {
                              final playing =
                                  await _trimmer.videoPlaybackControl(
                                startValue: _startValue,
                                endValue: _endValue,
                              );
                              if (mounted) {
                                setState(() => _isPlaying = playing);
                              }
                            },
                      icon: Icon(
                        _isPlaying
                            ? Icons.pause_circle_filled_rounded
                            : Icons.play_circle_filled_rounded,
                        color: Colors.white,
                        size: 56,
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        child: Text(
                          'Clips de perfil: hasta $hintMax s · Arrastrá los extremos',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
