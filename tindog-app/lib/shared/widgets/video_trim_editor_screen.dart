import 'dart:io';

import 'package:flutter/material.dart';
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
  if (!context.mounted) return null;
  return Navigator.of(context).push<File>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => VideoTrimEditorScreen(
        videoFile: videoFile,
        maxLength: maxLength,
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
  final Duration maxLength;
  final int limitLabelSec;

  @override
  State<VideoTrimEditorScreen> createState() => _VideoTrimEditorScreenState();
}

class _VideoTrimEditorScreenState extends State<VideoTrimEditorScreen>
    with WidgetsBindingObserver {
  final _trimmer = Trimmer();
  double _startValue = 0;
  double _endValue = 0;
  var _isPlaying = false;
  var _saving = false;
  var _ready = false;
  var _trimBarReady = false;
  String? _loadError;

  static const _trimBarHeight = 72.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Importante: montar TrimViewer en el primer frame y recién después
    // cargar el video. Si loadVideo corre antes, TrimViewer se pierde el
    // evento `initialized` y queda en SizedBox vacío (barra invisible).
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopPlayback();
    _trimmer.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _stopPlayback();
    }
  }

  void _stopPlayback() {
    try {
      final controller = _trimmer.videoPlayerController;
      if (controller != null && controller.value.isInitialized) {
        controller.pause();
      }
    } catch (_) {}
    if (mounted && _isPlaying) {
      setState(() => _isPlaying = false);
    } else {
      _isPlaying = false;
    }
  }

  Future<void> _closeWithoutSave() async {
    _stopPlayback();
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _load() async {
    try {
      await _trimmer.loadVideo(videoFile: widget.videoFile);
      final totalMs =
          _trimmer.videoPlayerController?.value.duration.inMilliseconds ?? 0;
      final maxMs = widget.maxLength.inMilliseconds;
      _startValue = 0;
      _endValue =
          maxMs > 0 && totalMs > maxMs ? maxMs.toDouble() : totalMs.toDouble();
      if (!mounted) return;
      setState(() => _ready = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadError = 'No se pudo abrir el video');
    }
  }

  String get _selectionLabel {
    final spanSec = ((_endValue - _startValue).abs() / 1000).clamp(0, 9999);
    if (spanSec < 0.05) {
      return 'Elegí el tramo que querés guardar';
    }
    final selected = spanSec < 10
        ? spanSec.toStringAsFixed(1)
        : spanSec.round().toString();
    return 'Vas a guardar $selected s (máximo ${widget.limitLabelSec} s)';
  }

  Future<void> _save() async {
    if (_saving || !_ready) return;
    _stopPlayback();
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
        _stopPlayback();
        Navigator.pop(context, File(outputPath));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final trimWidth = MediaQuery.sizeOf(context).width;

    return PopScope(
      canPop: !_saving,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _stopPlayback();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: const Text(
            'Elegí el tramo',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          leading: IconButton(
            onPressed: _saving ? null : _closeWithoutSave,
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
                      'Guardar',
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
            : Column(
                children: [
                  if (_saving)
                    const LinearProgressIndicator(
                      color: AppColors.primary,
                      backgroundColor: Colors.white12,
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                    child: Text(
                      'En el perfil solo podés subir clips de hasta '
                      '${widget.limitLabelSec} segundos.\n'
                      'Mové las barras verdes de los costados para marcar '
                      'el inicio y el final.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _ready
                        ? VideoViewer(trimmer: _trimmer)
                        : const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                  ),
                  // TrimViewer tiene que estar en el árbol ANTES de loadVideo.
                  Container(
                    width: double.infinity,
                    color: const Color(0xFF1A1A1A),
                    padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: _trimBarHeight + 28,
                          width: trimWidth,
                          child: TrimViewer(
                            trimmer: _trimmer,
                            type: ViewerType.fixed,
                            viewerHeight: _trimBarHeight,
                            viewerWidth: trimWidth,
                            maxVideoLength: widget.maxLength,
                            showDuration: true,
                            durationStyle: DurationStyle.FORMAT_MM_SS,
                            durationTextStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            editorProperties: TrimEditorProperties(
                              borderPaintColor: AppColors.primary,
                              circlePaintColor: Colors.white,
                              scrubberPaintColor: Colors.white,
                              borderWidth: 3,
                              borderRadius: 8,
                              circleSize: 8,
                            ),
                            areaProperties: TrimAreaProperties(
                              thumbnailQuality: 50,
                              borderRadius: 8,
                            ),
                            onThumbnailLoadingComplete: () {
                              if (mounted && !_trimBarReady) {
                                setState(() => _trimBarReady = true);
                              }
                            },
                            onChangeStart: (v) {
                              _startValue = v;
                              if (mounted) setState(() {});
                            },
                            onChangeEnd: (v) {
                              _endValue = v;
                              if (mounted) setState(() {});
                            },
                            onChangePlaybackState: (playing) {
                              if (mounted) {
                                setState(() => _isPlaying = playing);
                              }
                            },
                          ),
                        ),
                        if (_ready && !_trimBarReady)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              'Cargando barra de recorte…',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: (_saving || !_ready)
                        ? null
                        : () async {
                            final playing = await _trimmer.videoPlaybackControl(
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
                        _selectionLabel,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
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
