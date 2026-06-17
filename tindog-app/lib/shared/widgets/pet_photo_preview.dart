import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';

class PetPhotoPreview extends StatefulWidget {
  const PetPhotoPreview({
    super.key,
    this.photoUrl,
    this.localImageBytes,
    this.localFile,
    this.borderRadius = 24,
    this.placeholderAspectRatio = 4 / 3,
  });

  final String? photoUrl;
  final Uint8List? localImageBytes;
  final File? localFile;
  final double borderRadius;
  final double placeholderAspectRatio;

  @override
  State<PetPhotoPreview> createState() => _PetPhotoPreviewState();
}

class _PetPhotoPreviewState extends State<PetPhotoPreview> {
  double? _aspectRatio;

  @override
  void initState() {
    super.initState();
    _resolveAspectRatio();
  }

  @override
  void didUpdateWidget(PetPhotoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photoUrl != widget.photoUrl ||
        oldWidget.localImageBytes != widget.localImageBytes ||
        oldWidget.localFile != widget.localFile) {
      _aspectRatio = null;
      _resolveAspectRatio();
    }
  }

  Future<void> _resolveAspectRatio() async {
    try {
      final ratio = await _loadAspectRatio();
      if (!mounted || ratio == null) return;
      setState(() => _aspectRatio = ratio);
    } catch (_) {
      if (!mounted) return;
      setState(() => _aspectRatio = widget.placeholderAspectRatio);
    }
  }

  Future<double?> _loadAspectRatio() async {
    if (widget.localImageBytes != null) {
      return _aspectRatioFromBytes(widget.localImageBytes!);
    }
    if (widget.localFile != null) {
      return _aspectRatioFromBytes(await widget.localFile!.readAsBytes());
    }
    if (widget.photoUrl != null && widget.photoUrl!.isNotEmpty) {
      return _aspectRatioFromUrl(widget.photoUrl!);
    }
    return null;
  }

  Future<double> _aspectRatioFromBytes(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image.width / frame.image.height;
  }

  Future<double> _aspectRatioFromUrl(String url) async {
    final completer = Completer<ImageInfo>();
    final stream =
        CachedNetworkImageProvider(url).resolve(const ImageConfiguration());
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        stream.removeListener(listener);
        if (!completer.isCompleted) completer.complete(info);
      },
      onError: (error, _) {
        stream.removeListener(listener);
        if (!completer.isCompleted) completer.completeError(error);
      },
    );
    stream.addListener(listener);
    final info = await completer.future;
    return info.image.width / info.image.height;
  }

  @override
  Widget build(BuildContext context) {
    final ratio = _aspectRatio ?? widget.placeholderAspectRatio;

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: AspectRatio(
        aspectRatio: ratio,
        child: _aspectRatio == null ? _buildPlaceholder() : _buildImage(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Shimmer.fromColors(
      baseColor: AppColors.border,
      highlightColor: Colors.white,
      child: const ColoredBox(color: AppColors.border),
    );
  }

  Widget _buildImage() {
    if (widget.localImageBytes != null) {
      return Image.memory(
        widget.localImageBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    if (widget.localFile != null) {
      return Image.file(
        widget.localFile!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    if (widget.photoUrl != null && widget.photoUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: widget.photoUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (_, _) => _buildPlaceholder(),
        errorWidget: (_, _, _) => const ColoredBox(
          color: AppColors.border,
          child: Icon(Icons.pets, size: 48, color: AppColors.textSecondary),
        ),
      );
    }
    return const ColoredBox(
      color: AppColors.border,
      child: Icon(Icons.pets, size: 48, color: AppColors.textSecondary),
    );
  }
}
