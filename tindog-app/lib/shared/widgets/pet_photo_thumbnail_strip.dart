import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../models/swipe_preview_media.dart';

class PetPhotoThumbnailStrip extends StatefulWidget {
  const PetPhotoThumbnailStrip({
    super.key,
    required this.mediaItems,
    required this.selectedIndex,
    this.onSelected,
  });

  final List<SwipePreviewMediaItem> mediaItems;
  final int selectedIndex;
  final ValueChanged<int>? onSelected;

  @override
  State<PetPhotoThumbnailStrip> createState() => _PetPhotoThumbnailStripState();
}

class _PetPhotoThumbnailStripState extends State<PetPhotoThumbnailStrip> {
  static const _thumbSize = 60.0;
  static const _thumbGap = 10.0;

  final _scrollController = ScrollController();
  final _thumbKeys = <GlobalKey>[];

  @override
  void initState() {
    super.initState();
    _syncThumbKeys();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  @override
  void didUpdateWidget(PetPhotoThumbnailStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncThumbKeys();
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _syncThumbKeys() {
    while (_thumbKeys.length < widget.mediaItems.length) {
      _thumbKeys.add(GlobalKey());
    }
    while (_thumbKeys.length > widget.mediaItems.length) {
      _thumbKeys.removeLast();
    }
  }

  void _scrollToSelected() {
    if (!_scrollController.hasClients || widget.mediaItems.length <= 1) return;

    final key = _thumbKeys[widget.selectedIndex.clamp(
      0,
      widget.mediaItems.length - 1,
    )];
    final context = key.currentContext;
    if (context == null) return;

    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: 0.5,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mediaItems.length <= 1) return const SizedBox.shrink();

    return SizedBox(
      height: _thumbSize + 8,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: widget.mediaItems.length,
        separatorBuilder: (_, _) => const SizedBox(width: _thumbGap),
        itemBuilder: (context, index) {
          final selected = index == widget.selectedIndex;
          final item = widget.mediaItems[index];

          return KeyedSubtree(
            key: _thumbKeys[index],
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onSelected == null
                    ? null
                    : () {
                        if (index != widget.selectedIndex) {
                          HapticFeedback.selectionClick();
                        }
                        widget.onSelected!(index);
                      },
                borderRadius: BorderRadius.circular(14),
                child: AnimatedScale(
                  scale: selected ? 1.0 : 0.92,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    width: _thumbSize,
                    height: _thumbSize,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? AppColors.accent : AppColors.border,
                        width: selected ? 2.5 : 1,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.28),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 220),
                      opacity: selected ? 1 : 0.72,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (item.isVideo)
                            CachedNetworkImage(
                              imageUrl: item.thumbnailUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, _) => _videoThumbFallback(),
                              errorWidget: (_, _, _) => _videoThumbFallback(),
                            )
                          else
                            CachedNetworkImage(
                              imageUrl: item.url,
                              fit: BoxFit.cover,
                              errorWidget: (_, _, _) => const ColoredBox(
                                color: AppColors.border,
                                child: Icon(Icons.broken_image_outlined),
                              ),
                            ),
                          if (item.isVideo)
                            Container(
                              color: Colors.black.withValues(alpha: 0.28),
                              child: const Center(
                                child: Icon(
                                  Icons.play_circle_fill,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

Widget _videoThumbFallback() {
  return ColoredBox(
    color: Colors.black87,
    child: Icon(
      Icons.videocam_outlined,
      color: Colors.white.withValues(alpha: 0.7),
    ),
  );
}
