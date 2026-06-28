import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../core/network/session_handler.dart';
import '../../core/theme/app_colors.dart';

class PetVideoPlayerScreen extends StatefulWidget {
  const PetVideoPlayerScreen({
    super.key,
    required this.url,
    this.title,
  });

  final String url;
  final String? title;

  @override
  State<PetVideoPlayerScreen> createState() => _PetVideoPlayerScreenState();
}

class _PetVideoPlayerScreenState extends State<PetVideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _ready = false;
  String? _error;
  double? _seekDragValue;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initPlayer());
  }

  Future<void> _initPlayer() async {
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.url),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );

    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _ready = true;
      });
      await controller.play();
      controller.addListener(_onPlaybackChanged);
    } catch (error) {
      await controller.dispose();
      if (!mounted) return;
      setState(() => _error = _readableVideoError(error));
    }
  }

  void _onPlaybackChanged() {
    if (mounted && _seekDragValue == null) setState(() {});
  }

  String _readableVideoError(Object error) {
    final message = error.toString();
    if (message.contains('channel-error') ||
        message.contains('AndroidVideoPlayerApi')) {
      return 'No se pudo iniciar el reproductor. '
          'Cerrá la app por completo y volvé a abrirla '
          '(hot reload no alcanza después de instalar video).';
    }
    return readableError(error);
  }

  Future<void> _seekTo(double milliseconds) async {
    final controller = _controller;
    if (controller == null) return;
    await controller.seekTo(Duration(milliseconds: milliseconds.round()));
  }

  void _togglePlay() {
    final controller = _controller;
    if (controller == null) return;

    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onPlaybackChanged);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title ?? 'Video'),
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : !_ready || controller == null
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : Column(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _togglePlay,
                        behavior: HitTestBehavior.opaque,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Center(
                              child: AspectRatio(
                                aspectRatio: controller.value.aspectRatio,
                                child: VideoPlayer(controller),
                              ),
                            ),
                            if (!controller.value.isPlaying)
                              IgnorePointer(
                                child: Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 52,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    _VideoSeekBar(
                      controller: controller,
                      seekDragValue: _seekDragValue,
                      onDragStart: (value) =>
                          setState(() => _seekDragValue = value),
                      onDragUpdate: (value) =>
                          setState(() => _seekDragValue = value),
                      onDragEnd: (value) async {
                        await _seekTo(value);
                        if (mounted) setState(() => _seekDragValue = null);
                      },
                      onTogglePlay: _togglePlay,
                    ),
                    SizedBox(height: bottomInset + 8),
                  ],
                ),
    );
  }
}

class _VideoSeekBar extends StatelessWidget {
  const _VideoSeekBar({
    required this.controller,
    required this.seekDragValue,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onTogglePlay,
  });

  final VideoPlayerController controller;
  final double? seekDragValue;
  final ValueChanged<double> onDragStart;
  final ValueChanged<double> onDragUpdate;
  final ValueChanged<double> onDragEnd;
  final VoidCallback onTogglePlay;

  @override
  Widget build(BuildContext context) {
    final durationMs = controller.value.duration.inMilliseconds;
    final maxMs = durationMs > 0 ? durationMs.toDouble() : 1.0;
    final positionMs = seekDragValue ??
        controller.value.position.inMilliseconds.toDouble().clamp(0, maxMs);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: AppColors.accent,
              inactiveTrackColor: Colors.white24,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.accent.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: positionMs.clamp(0, maxMs),
              max: maxMs,
              onChangeStart: (_) => onDragStart(positionMs),
              onChanged: onDragUpdate,
              onChangeEnd: onDragEnd,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: onTogglePlay,
                  color: Colors.white,
                  iconSize: 32,
                  icon: Icon(
                    controller.value.isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                  ),
                ),
                Text(
                  _formatDuration(Duration(milliseconds: positionMs.round())),
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const Spacer(),
                Text(
                  _formatDuration(controller.value.duration),
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(1, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}
