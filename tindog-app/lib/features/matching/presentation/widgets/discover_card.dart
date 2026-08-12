import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/feedback/app_haptics.dart';
import '../../../../shared/models/swipe_preview_media.dart';
import '../../../../shared/widgets/pet_card_overlay.dart';
import '../../data/discover_candidate.dart';
import '../discover_providers.dart';

class DiscoverCardController {
  _DiscoverCardState? _state;

  void _attach(_DiscoverCardState state) => _state = state;

  void _detach(_DiscoverCardState state) {
    if (_state == state) _state = null;
  }

  void like() => _state?._commit(DiscoverSwipeDecision.like);

  void pass() => _state?._commit(DiscoverSwipeDecision.pass);
}

/// Card full-bleed de discovery (otros perfiles) con like/pass que descartan.
class DiscoverCard extends StatefulWidget {
  const DiscoverCard({
    super.key,
    required this.candidate,
    required this.onDecision,
    this.controller,
    this.bottomBar,
    this.onOpenGallery,
    this.onOwnerTap,
    this.storyTopInset = 12,
  });

  final DiscoverCandidate candidate;
  final ValueChanged<DiscoverSwipeDecision> onDecision;
  final DiscoverCardController? controller;
  final Widget? bottomBar;
  /// Índice de la foto actual → galería fullscreen.
  final ValueChanged<int>? onOpenGallery;
  /// Chip del dueño / Ver más → ficha con sección Dueño/a.
  final VoidCallback? onOwnerTap;
  final double storyTopInset;

  @override
  State<DiscoverCard> createState() => _DiscoverCardState();
}

class _DiscoverCardState extends State<DiscoverCard>
    with SingleTickerProviderStateMixin {
  static const _maxDrag = 160.0;
  static const _commitThreshold = 90.0;
  static const _tapThreshold = 12.0;

  double _dragX = 0;
  double _totalDrag = 0;
  int _photoIndex = 0;
  late final AnimationController _flyController;
  Animation<double>? _flyAnimation;
  bool _committing = false;

  List<SwipePreviewMediaItem> get _media => widget.candidate.mediaItems;

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
    _flyController = AnimationController(vsync: this)
      ..addListener(() {
        if (_flyAnimation != null) {
          setState(() => _dragX = _flyAnimation!.value);
        }
      });
  }

  @override
  void didUpdateWidget(DiscoverCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
    if (widget.candidate.id != oldWidget.candidate.id) {
      _photoIndex = 0;
      _dragX = 0;
      _committing = false;
    }
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    _flyController.dispose();
    super.dispose();
  }

  Future<void> _commit(DiscoverSwipeDecision decision) async {
    if (!mounted || _committing) return;
    _committing = true;

    final width = MediaQuery.sizeOf(context).width;
    final target =
        decision == DiscoverSwipeDecision.like ? width * 1.25 : -width * 1.25;

    _flyController.duration = const Duration(milliseconds: 280);
    _flyAnimation = Tween<double>(begin: _dragX, end: target).animate(
      CurvedAnimation(parent: _flyController, curve: Curves.easeInCubic),
    );
    if (decision == DiscoverSwipeDecision.like) {
      AppHaptics.like();
    } else {
      AppHaptics.pass();
    }
    await _flyController.forward(from: 0);
    if (!mounted) return;
    widget.onDecision(decision);
  }

  void _onDragEnd() {
    if (_committing) return;
    if (_dragX.abs() >= _commitThreshold) {
      _commit(
        _dragX > 0 ? DiscoverSwipeDecision.like : DiscoverSwipeDecision.pass,
      );
      return;
    }
    setState(() => _dragX = 0);
  }

  void _onTapUp(TapUpDetails details, double width) {
    if (_totalDrag > _tapThreshold) return;
    final x = details.localPosition.dx;
    final mediaIndex =
        _photoIndex.clamp(0, _media.isEmpty ? 0 : _media.length - 1);
    final current = _media.isEmpty ? null : _media[mediaIndex];

    if (_media.length > 1) {
      if (x < width * 0.35 && _photoIndex > 0) {
        setState(() => _photoIndex -= 1);
        AppHaptics.selection();
        return;
      }
      if (x > width * 0.65 && _photoIndex < _media.length - 1) {
        setState(() => _photoIndex += 1);
        AppHaptics.selection();
        return;
      }
    }

    if (current != null &&
        current.isVideo &&
        widget.onOpenGallery != null &&
        x >= width * 0.3 &&
        x <= width * 0.7) {
      widget.onOpenGallery!(mediaIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rotation = _dragX * 0.0009;
    final likeOpacity = _dragX > 0 ? (_dragX / 80).clamp(0.0, 1.0) : 0.0;
    final passOpacity = _dragX < 0 ? (-_dragX / 80).clamp(0.0, 1.0) : 0.0;
    final candidate = widget.candidate;
    final breed = candidate.breed?.trim();
    final bio = candidate.bio?.trim();
    final subtitle = (breed != null && breed.isNotEmpty) ? breed : null;
    final mediaIndex = _photoIndex.clamp(0, _media.isEmpty ? 0 : _media.length - 1);
    final currentMedia = _media.isEmpty ? null : _media[mediaIndex];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        return GestureDetector(
          onTapDown: (_) => _totalDrag = 0,
          onTapUp: (d) => _onTapUp(d, width),
          onHorizontalDragUpdate: (d) {
            if (_committing) return;
            setState(() {
              _totalDrag += d.delta.dx.abs();
              _dragX = (_dragX + d.delta.dx).clamp(-_maxDrag, _maxDrag);
            });
          },
          onHorizontalDragEnd: (_) => _onDragEnd(),
          onHorizontalDragCancel: _onDragEnd,
          child: Transform.translate(
            offset: Offset(_dragX, 0),
            child: Transform.rotate(
              angle: rotation,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: Colors.black,
                    child: currentMedia == null
                        ? const ColoredBox(
                            color: Color(0xFF1A1A1A),
                            child: Icon(
                              Icons.pets,
                              color: Colors.white38,
                              size: 64,
                            ),
                          )
                        : Stack(
                            fit: StackFit.expand,
                            children: [
                              CachedNetworkImage(
                                imageUrl: currentMedia.thumbnailUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                alignment: Alignment.topCenter,
                                placeholder: (_, _) =>
                                    const ColoredBox(color: Color(0xFF1A1A1A)),
                                errorWidget: (_, _, _) => const ColoredBox(
                                  color: Color(0xFF1A1A1A),
                                  child: Icon(
                                    Icons.pets,
                                    color: Colors.white38,
                                    size: 64,
                                  ),
                                ),
                              ),
                              if (currentMedia.isVideo)
                                Center(
                                  child: IgnorePointer(
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.4,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: 48,
                                      ),
                                    ),
                                  ),
                                ),
                              if (currentMedia.isVideo &&
                                  currentMedia.durationSec != null)
                                Positioned(
                                  right: 14,
                                  bottom: 120,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.55),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.videocam_rounded,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          formatMediaDuration(
                                            currentMedia.durationSec!,
                                          ),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x66000000),
                          Color(0x00000000),
                          Color(0x59000000),
                          Color(0xB3000000),
                        ],
                        stops: [0, 0.28, 0.55, 1],
                      ),
                    ),
                  ),
                  if (_media.length > 1)
                    Positioned(
                      top: widget.storyTopInset,
                      left: 12,
                      right: 12,
                      child: Row(
                        children: List.generate(_media.length, (i) {
                          final active = i == mediaIndex;
                          return Expanded(
                            child: Container(
                              height: active ? 3.5 : 2.5,
                              margin: EdgeInsets.only(
                                right: i == _media.length - 1 ? 0 : 4,
                              ),
                              decoration: BoxDecoration(
                                color: active
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.32),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  Positioned(
                    top: constraints.maxHeight * 0.14,
                    left: 20,
                    child: _Stamp(
                      label: 'NOPE',
                      color: const Color(0xFFFF4458),
                      opacity: passOpacity,
                      rotation: -0.4,
                    ),
                  ),
                  Positioned(
                    top: constraints.maxHeight * 0.14,
                    right: 20,
                    child: _Stamp(
                      label: 'LIKE',
                      color: const Color(0xFF4CD964),
                      opacity: likeOpacity,
                      rotation: 0.4,
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.05),
                                Colors.black.withValues(alpha: 0.55),
                                Colors.black.withValues(alpha: 0.75),
                              ],
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              18,
                              18,
                              18,
                              widget.bottomBar != null ? 14 : 22,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (candidate.isActive)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.circle,
                                          size: 8,
                                          color: Color(0xFF34C759),
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'Activo',
                                          style: TextStyle(
                                            color: Color(0xFF1A1A1A),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (candidate.isActive) const SizedBox(height: 10),
                                PetCardOverlay(
                                  name: candidate.name,
                                  age: candidate.age,
                                  subtitle: subtitle,
                                  ownerName: candidate.ownerName,
                                  ownerAvatarUrl: candidate.ownerAvatarUrl,
                                  ownerGoogleLinked:
                                      candidate.ownerGoogleLinked,
                                  bio: (bio != null && bio.isNotEmpty)
                                      ? bio
                                      : null,
                                  onInfoTap: widget.onOpenGallery == null
                                      ? null
                                      : () => widget.onOpenGallery!(mediaIndex),
                                  onOwnerTap: widget.onOwnerTap,
                                  onBioMoreTap: widget.onOwnerTap,
                                ),
                                if (candidate.locationLabel != null) ...[
                                  const SizedBox(height: 8),
                                  _InfoLine(
                                    icon: Icons.home_outlined,
                                    text: candidate.locationLabel!,
                                  ),
                                ],
                                if (candidate.distanceLabel != null) ...[
                                  const SizedBox(height: 4),
                                  _InfoLine(
                                    icon: Icons.near_me_outlined,
                                    text: candidate.distanceLabel!,
                                  ),
                                ],
                                if (candidate.proximityTip != null) ...[
                                  const SizedBox(height: 4),
                                  _InfoLine(
                                    icon: Icons.pets_rounded,
                                    text: candidate.proximityTip!,
                                  ),
                                ],
                                if (widget.bottomBar != null) ...[
                                  const SizedBox(height: 18),
                                  widget.bottomBar!,
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.9)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp({
    required this.label,
    required this.color,
    required this.opacity,
    required this.rotation,
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
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 4),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 24,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}
