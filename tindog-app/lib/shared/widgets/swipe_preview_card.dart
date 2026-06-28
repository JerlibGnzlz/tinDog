import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../models/swipe_preview_media.dart';
import 'pet_video_player_screen.dart';
import 'pet_photo_viewer_screen.dart';

enum SwipePreviewDecision { like, pass }

class SwipePreviewCardController {
  _SwipePreviewCardState? _state;

  void _attach(_SwipePreviewCardState state) => _state = state;

  void _detach(_SwipePreviewCardState state) {
    if (_state == state) _state = null;
  }

  void previewLike() => _state?._previewDecision(isLike: true);

  void previewPass() => _state?._previewDecision(isLike: false);
}

/// Vista previa visual del swipe (sin like/pass real). La tarjeta vuelve al centro.
class SwipePreviewCard extends StatefulWidget {
  const SwipePreviewCard({
    super.key,
    required this.mediaItems,
    required this.mediaIndex,
    this.petName,
    this.maxHeight = 420,
    this.controller,
    this.onMediaIndexChanged,
    this.onPreviewDecision,
  });

  final List<SwipePreviewMediaItem> mediaItems;
  final int mediaIndex;
  final String? petName;
  final double maxHeight;
  final SwipePreviewCardController? controller;
  final ValueChanged<int>? onMediaIndexChanged;
  final ValueChanged<SwipePreviewDecision>? onPreviewDecision;

  @override
  State<SwipePreviewCard> createState() => _SwipePreviewCardState();
}

class _SwipePreviewCardState extends State<SwipePreviewCard>
    with TickerProviderStateMixin {
  static const _maxCardDrag = 140.0;
  static const _decisionDragTarget = 110.0;
  static const _decisionFeedbackThreshold = 40.0;
  static const _tapDragThreshold = 12.0;
  static const _photoCommitFraction = 0.16;
  static const _cardIntentDistance = 62.0;
  static const _mediaSwitchDuration = Duration(milliseconds: 320);
  static const _photoSnapDuration = Duration(milliseconds: 220);

  double _cardDragX = 0;
  double _photoDragX = 0;
  double _gestureDragX = 0;
  double _totalDragDistance = 0;
  int _slideDirection = 1;
  _DragIntent _dragIntent = _DragIntent.none;

  late final AnimationController _photoSnapController;
  late final AnimationController _decisionController;
  Animation<double>? _photoSnapAnimation;
  Animation<double>? _decisionAnimation;

  int get _mediaIndex =>
      widget.mediaIndex.clamp(0, widget.mediaItems.length - 1);

  bool get _hasMultipleItems => widget.mediaItems.length > 1;

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
    _photoSnapController = AnimationController(
      vsync: this,
      duration: _photoSnapDuration,
    )
      ..addListener(() {
        if (_photoSnapAnimation != null) {
          setState(() => _photoDragX = _photoSnapAnimation!.value);
        }
      })
      ..addStatusListener((status) {
        if (status != AnimationStatus.completed) return;
        _photoDragX = 0;
        _photoSnapAnimation = null;
        _photoSnapController.reset();
        if (mounted) setState(() {});
      });
    _decisionController = AnimationController(vsync: this)
      ..addListener(() {
        if (_decisionAnimation != null) {
          setState(() => _cardDragX = _decisionAnimation!.value);
        }
      });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _precacheAdjacentPhotos();
    });
  }

  @override
  void didUpdateWidget(SwipePreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
    if (widget.mediaIndex != oldWidget.mediaIndex) {
      _slideDirection = widget.mediaIndex > oldWidget.mediaIndex ? 1 : -1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _precacheAdjacentPhotos();
      });
    }
    if (widget.mediaItems != oldWidget.mediaItems) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _precacheAdjacentPhotos();
      });
    }
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    _photoSnapController.dispose();
    _decisionController.dispose();
    super.dispose();
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    _photoSnapController.stop();
    _photoSnapAnimation = null;
    _gestureDragX = 0;
    _totalDragDistance = 0;
    _dragIntent = _DragIntent.none;
  }

  bool _shouldUseCardMode(double dragX) {
    if (!_hasMultipleItems) return true;
    if (_dragIntent == _DragIntent.card) return true;

    final atFirst = _mediaIndex == 0;
    final atLast = _mediaIndex == widget.mediaItems.length - 1;

    if (atLast && dragX < -8) return true;
    if (atFirst && dragX > 8) return true;
    if (dragX.abs() >= _cardIntentDistance) return true;

    return false;
  }

  void _applyCardDrag(double dragX) {
    _dragIntent = _DragIntent.card;
    _photoDragX = 0;
    _cardDragX = dragX.clamp(-_maxCardDrag, _maxCardDrag);
  }

  void _applyPhotoDrag(double dragX, double width) {
    _dragIntent = _DragIntent.photo;
    _cardDragX = 0;
    _photoDragX = dragX.clamp(-width * 0.42, width * 0.42);
  }

  void _stopPhotoSnapAnimation() {
    _photoSnapController.stop();
    _photoSnapAnimation = null;
    _photoSnapController.reset();
  }

  void _snapPhotoDragBack() {
    if (_photoDragX == 0) return;

    _photoSnapAnimation = Tween<double>(
      begin: _photoDragX,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _photoSnapController,
      curve: Curves.easeOutCubic,
    ));
    _photoSnapController.forward(from: 0);
  }

  void _commitPhotoSwipe(int index) {
    _stopPhotoSnapAnimation();
    _slideDirection = index > _mediaIndex ? 1 : -1;
    setState(() {
      _photoDragX = 0;
      _cardDragX = 0;
      _gestureDragX = 0;
      _dragIntent = _DragIntent.none;
    });
    _goToPage(index);
  }

  void _resolvePhotoDrag(DragEndDetails details, double width) {
    final velocity = details.primaryVelocity ?? 0;
    final threshold = width * _photoCommitFraction;

    final goNext = (_photoDragX < -threshold || velocity < -420) &&
        _mediaIndex < widget.mediaItems.length - 1;
    final goPrev = (_photoDragX > threshold || velocity > 420) &&
        _mediaIndex > 0;

    if (goNext) {
      _commitPhotoSwipe(_mediaIndex + 1);
      return;
    }

    if (goPrev) {
      _commitPhotoSwipe(_mediaIndex - 1);
      return;
    }

    _snapPhotoDragBack();
    setState(() {
      _cardDragX = 0;
      _dragIntent = _DragIntent.none;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details, double width) {
    if (_dragIntent == _DragIntent.card) {
      final wasLike = _cardDragX >= _decisionFeedbackThreshold;
      final wasPass = _cardDragX <= -_decisionFeedbackThreshold;
      setState(() {
        _cardDragX = 0;
        _photoDragX = 0;
        _gestureDragX = 0;
        _dragIntent = _DragIntent.none;
      });
      if (wasLike) {
        _emitPreviewDecision(isLike: true);
      } else if (wasPass) {
        _emitPreviewDecision(isLike: false);
      }
      return;
    }

    if (_hasMultipleItems && _photoDragX != 0) {
      _resolvePhotoDrag(details, width);
      return;
    }

    setState(() {
      _cardDragX = 0;
      _photoDragX = 0;
      _gestureDragX = 0;
      _dragIntent = _DragIntent.none;
    });
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details, double width) {
    setState(() {
      _totalDragDistance += details.delta.dx.abs();
      _gestureDragX += details.delta.dx;

      if (_shouldUseCardMode(_gestureDragX)) {
        _applyCardDrag(_gestureDragX);
      } else {
        _applyPhotoDrag(_gestureDragX, width);
      }
    });
  }

  void _onTapDown(TapDownDetails details) {
    _totalDragDistance = 0;
  }

  void _onTapUp(TapUpDetails details) {
    if (_photoSnapController.isAnimating) return;
    if (_totalDragDistance > _tapDragThreshold) return;

    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final width = box.size.width;
    final x = details.localPosition.dx;
    final item = widget.mediaItems[_mediaIndex];

    if (item.isVideo && x >= width * 0.35 && x <= width * 0.65) {
      _playVideo(item);
      return;
    }

    if (!item.isVideo && x >= width * 0.35 && x <= width * 0.65) {
      _openPhoto(item);
      return;
    }

    if (widget.mediaItems.length <= 1) return;

    if (x < width * 0.35) {
      _goToPage(_mediaIndex - 1);
    } else if (x > width * 0.65) {
      _goToPage(_mediaIndex + 1);
    }
  }

  void _goToPage(int index) {
    if (index < 0 || index >= widget.mediaItems.length) return;
    if (index == _mediaIndex) return;
    _slideDirection = index > _mediaIndex ? 1 : -1;
    HapticFeedback.selectionClick();
    widget.onMediaIndexChanged?.call(index);
  }

  void _playVideo(SwipePreviewMediaItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PetVideoPlayerScreen(
          url: item.url,
          title: item.durationSec != null
              ? formatMediaDuration(item.durationSec!)
              : 'Video',
        ),
      ),
    );
  }

  void _openPhoto(SwipePreviewMediaItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PetPhotoViewerScreen(
          url: item.url,
          title: widget.petName,
        ),
      ),
    );
  }

  void _emitPreviewDecision({required bool isLike}) {
    HapticFeedback.mediumImpact();
    widget.onPreviewDecision?.call(
      isLike ? SwipePreviewDecision.like : SwipePreviewDecision.pass,
    );
  }

  Future<void> _previewDecision({required bool isLike}) async {
    if (!mounted || _decisionController.isAnimating) return;

    _stopPhotoSnapAnimation();
    setState(() {
      _photoDragX = 0;
      _gestureDragX = 0;
      _dragIntent = _DragIntent.card;
    });

    final target = isLike ? _decisionDragTarget : -_decisionDragTarget;

    _decisionController.duration = const Duration(milliseconds: 240);
    _decisionAnimation = Tween<double>(begin: 0, end: target).animate(
      CurvedAnimation(
        parent: _decisionController,
        curve: Curves.easeOutCubic,
      ),
    );
    await _decisionController.forward(from: 0);
    if (!mounted) return;

    _emitPreviewDecision(isLike: isLike);

    _decisionController.duration = const Duration(milliseconds: 220);
    _decisionAnimation = Tween<double>(begin: target, end: 0).animate(
      CurvedAnimation(
        parent: _decisionController,
        curve: Curves.easeInOut,
      ),
    );
    await _decisionController.forward(from: 0);
    if (!mounted) return;

    setState(() {
      _cardDragX = 0;
      _dragIntent = _DragIntent.none;
    });
  }

  void _precacheAdjacentPhotos() {
    if (widget.mediaItems.isEmpty) return;

    for (final offset in [-1, 1]) {
      final index = _mediaIndex + offset;
      if (index < 0 || index >= widget.mediaItems.length) continue;

      final item = widget.mediaItems[index];
      if (item.isVideo) continue;

      precacheImage(CachedNetworkImageProvider(item.url), context);
    }
  }

  double _stampOpacity(double dragOffsetX) {
    final distance = dragOffsetX.abs();
    if (distance < 4) return 0;

    final progress = ((distance - 4) / 36).clamp(0.0, 1.0);
    return (0.55 + progress * 0.45).clamp(0.0, 1.0);
  }

  Widget _buildMediaPage(SwipePreviewMediaItem item) {
    if (!item.isVideo) {
      return ColoredBox(
        color: AppColors.surface,
        child: CachedNetworkImage(
          imageUrl: item.url,
          fit: BoxFit.contain,
          width: double.infinity,
          height: widget.maxHeight,
          alignment: Alignment.center,
          placeholder: (_, _) => const ColoredBox(color: AppColors.surface),
          errorWidget: (_, _, _) => const ColoredBox(
            color: AppColors.surface,
            child: Icon(Icons.broken_image_outlined),
          ),
        ),
      );
    }

    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: item.thumbnailUrl,
            fit: BoxFit.contain,
            width: double.infinity,
            height: widget.maxHeight,
            alignment: Alignment.center,
            placeholder: (_, _) => ColoredBox(
              color: Colors.black.withValues(alpha: 0.9),
            ),
            errorWidget: (_, _, _) => ColoredBox(
              color: Colors.black.withValues(alpha: 0.9),
              child: const Icon(Icons.videocam_outlined, color: Colors.white54),
            ),
          ),
          Center(
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 56,
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: IgnorePointer(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.videocam_rounded, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'VIDEO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (item.durationSec != null)
            Positioned(
              right: 12,
              bottom: 12,
              child: IgnorePointer(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    formatMediaDuration(item.durationSec!),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMediaCarousel(double width) {
    final isPhotoDragging =
        _photoDragX != 0 || _photoSnapController.isAnimating;

    if (!_hasMultipleItems || !isPhotoDragging) {
      return AnimatedSwitcher(
        duration: _mediaSwitchDuration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (currentChild, previousChildren) {
          return Stack(
            fit: StackFit.expand,
            children: [
              ...previousChildren,
              ?currentChild,
            ],
          );
        },
        transitionBuilder: (child, animation) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          final isIncoming = animation.status != AnimationStatus.reverse;

          final slideOffset = isIncoming
              ? Offset(0.06 * _slideDirection, 0)
              : Offset(-0.04 * _slideDirection, 0);

          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: slideOffset,
                end: Offset.zero,
              ).animate(curved),
              child: ScaleTransition(
                scale: Tween<double>(
                  begin: isIncoming ? 0.97 : 1.0,
                  end: 1.0,
                ).animate(curved),
                child: child,
              ),
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_mediaIndex),
          child: _buildMediaPage(widget.mediaItems[_mediaIndex]),
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.hardEdge,
      fit: StackFit.expand,
      children: _photoPeekLayers(width),
    );
  }

  List<Widget> _photoPeekLayers(double width) {
    final layers = <Widget>[];

    void addLayer(int index, double offset) {
      if (index < 0 || index >= widget.mediaItems.length) return;
      final distance = (offset - _photoDragX).abs();
      final fade = (1 - (distance / width).clamp(0.0, 1.0) * 0.35)
          .clamp(0.65, 1.0);

      layers.add(
        Positioned.fill(
          child: Transform.translate(
            offset: Offset(offset, 0),
            child: Opacity(
              opacity: fade,
              child: _buildMediaPage(widget.mediaItems[index]),
            ),
          ),
        ),
      );
    }

    addLayer(_mediaIndex - 1, _photoDragX - width);
    addLayer(_mediaIndex, _photoDragX);
    addLayer(_mediaIndex + 1, _photoDragX + width);

    return layers;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mediaItems.isEmpty) {
      return SizedBox(
        height: widget.maxHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
          ),
          child: const Center(
            child: Icon(Icons.pets, size: 56, color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final rotation = _cardDragX * 0.00085;
    final likeOpacity = _cardDragX > 0 ? _stampOpacity(_cardDragX) : 0.0;
    final passOpacity = _cardDragX < 0 ? _stampOpacity(_cardDragX) : 0.0;
    final stampTop = widget.maxHeight * 0.14;
    final hasMultipleItems = widget.mediaItems.length > 1;

    return SizedBox(
      height: widget.maxHeight + 12,
      width: double.infinity,
      child: Align(
        alignment: Alignment.center,
        child: SizedBox(
          height: widget.maxHeight,
          width: double.infinity,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = constraints.maxWidth;

              return GestureDetector(
                onTapDown: _onTapDown,
                onTapUp: _onTapUp,
                onHorizontalDragStart: _onHorizontalDragStart,
                onHorizontalDragUpdate: (details) =>
                    _onHorizontalDragUpdate(details, cardWidth),
                onHorizontalDragEnd: (details) =>
                    _onHorizontalDragEnd(details, cardWidth),
                onHorizontalDragCancel: () => _onHorizontalDragEnd(
                  DragEndDetails(primaryVelocity: 0, velocity: Velocity.zero),
                  cardWidth,
                ),
                child: Transform.translate(
                  offset: Offset(_cardDragX, 0),
                  child: Transform.rotate(
                    angle: rotation,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: SizedBox(
                            height: widget.maxHeight,
                            width: double.infinity,
                            child: _buildMediaCarousel(cardWidth),
                          ),
                        ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.45),
                              ],
                              stops: const [0.55, 1],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (widget.petName != null && widget.petName!.isNotEmpty)
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: IgnorePointer(
                          child: Text(
                            widget.petName!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: stampTop,
                      left: 20,
                      child: IgnorePointer(
                        child: _SwipeStamp(
                          label: 'NOPE',
                          color: const Color(0xFFEF5350),
                          opacity: passOpacity,
                          rotation: -0.4,
                        ),
                      ),
                    ),
                    Positioned(
                      top: stampTop,
                      right: 20,
                      child: IgnorePointer(
                        child: _SwipeStamp(
                          label: 'LIKE',
                          color: AppColors.accent,
                          opacity: likeOpacity,
                          rotation: 0.4,
                        ),
                      ),
                    ),
                    if (hasMultipleItems) ...[
                      Positioned(
                        top: 10,
                        left: 10,
                        right: 10,
                        child: IgnorePointer(
                          child: Row(
                            children:
                                List.generate(widget.mediaItems.length, (i) {
                              final active = i == _mediaIndex;
                              return Expanded(
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 240),
                                  curve: Curves.easeOutCubic,
                                  height: active ? 3.5 : 2.5,
                                  margin: EdgeInsets.only(
                                    right: i == widget.mediaItems.length - 1
                                        ? 0
                                        : 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: active
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.32),
                                    borderRadius: BorderRadius.circular(999),
                                    boxShadow: active
                                        ? [
                                            BoxShadow(
                                              color: Colors.white
                                                  .withValues(alpha: 0.35),
                                              blurRadius: 4,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 14,
                        right: 14,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.42),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              child: Text(
                                '${_mediaIndex + 1}/${widget.mediaItems.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

enum _DragIntent { none, photo, card }

class _SwipeStamp extends StatelessWidget {
  const _SwipeStamp({
    required this.label,
    required this.color,
    required this.opacity,
    this.rotation = 0,
  });

  final String label;
  final Color color;
  final double opacity;
  final double rotation;

  @override
  Widget build(BuildContext context) {
    if (opacity <= 0) return const SizedBox.shrink();

    return Opacity(
      opacity: opacity,
      child: Transform.rotate(
        angle: rotation,
        child: Transform.scale(
          scale: 0.92 + opacity * 0.12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.18),
              border: Border.all(color: color, width: 4),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 26,
                letterSpacing: 2.5,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
