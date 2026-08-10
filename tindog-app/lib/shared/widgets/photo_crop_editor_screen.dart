import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Abre un editor fullscreen tipo WhatsApp: pellizcar para zoom, arrastrar para mover.
///
/// Devuelve los bytes recortados, o `null` si el usuario cancela.
Future<Uint8List?> openPhotoCropEditor({
  required BuildContext context,
  required Uint8List imageBytes,
  /// 3/4 encaja con cards de Discover / perfil de match.
  double aspectRatio = 3 / 4,
}) {
  return Navigator.of(context).push<Uint8List>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => PhotoCropEditorScreen(
        imageBytes: imageBytes,
        aspectRatio: aspectRatio,
      ),
    ),
  );
}

class PhotoCropEditorScreen extends StatefulWidget {
  const PhotoCropEditorScreen({
    super.key,
    required this.imageBytes,
    this.aspectRatio = 3 / 4,
  });

  final Uint8List imageBytes;
  final double aspectRatio;

  @override
  State<PhotoCropEditorScreen> createState() => _PhotoCropEditorScreenState();
}

class _PhotoCropEditorScreenState extends State<PhotoCropEditorScreen> {
  final _controller = CropController();
  var _busy = false;
  var _ready = false;

  void _onCropped(CropResult result) {
    if (!mounted) return;
    switch (result) {
      case CropSuccess(:final croppedImage):
        Navigator.pop(context, croppedImage);
      case CropFailure(:final cause):
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No se pudo recortar: $cause',
            ),
          ),
        );
    }
  }

  void _confirm() {
    if (_busy || !_ready) return;
    setState(() => _busy = true);
    _controller.crop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Cancelar',
        ),
        title: const Text(
          'Ajustar foto',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: (_busy || !_ready) ? null : _confirm,
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Text(
                    'Listo',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Crop(
              image: widget.imageBytes,
              controller: _controller,
              onCropped: _onCropped,
              aspectRatio: widget.aspectRatio,
              interactive: true,
              fixCropRect: true,
              baseColor: Colors.black,
              maskColor: Colors.black.withValues(alpha: 0.55),
              radius: 12,
              progressIndicator: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              onStatusChanged: (status) {
                final ready = status == CropStatus.ready;
                if (ready != _ready && mounted) {
                  setState(() => _ready = ready);
                }
              },
              willUpdateScale: (scale) => scale >= 1 && scale <= 8,
              cornerDotBuilder: (size, _) => const SizedBox.shrink(),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Text(
                'Pellizcá para zoom · Arrastrá para mover',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
