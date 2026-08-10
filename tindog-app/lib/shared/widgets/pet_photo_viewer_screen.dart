import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Galería fullscreen con zoom (pellizcar) y swipe entre fotos.
class PetPhotoViewerScreen extends StatefulWidget {
  const PetPhotoViewerScreen({
    super.key,
    required this.urls,
    this.initialIndex = 0,
    this.title,
  }) : assert(urls.length > 0, 'urls no puede estar vacío');

  /// Compat: una sola foto.
  factory PetPhotoViewerScreen.single({
    Key? key,
    required String url,
    String? title,
  }) {
    return PetPhotoViewerScreen(
      key: key,
      urls: [url],
      title: title,
    );
  }

  final List<String> urls;
  final int initialIndex;
  final String? title;

  @override
  State<PetPhotoViewerScreen> createState() => _PetPhotoViewerScreenState();
}

class _PetPhotoViewerScreenState extends State<PetPhotoViewerScreen> {
  late final PageController _pageController;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.urls.length - 1);
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.urls.length;
    final title = widget.title?.trim();
    final label = count > 1
        ? '${title == null || title.isEmpty ? 'Fotos' : title} · ${_index + 1}/$count'
        : (title == null || title.isEmpty ? 'Foto' : title);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text(label),
        ),
        body: PageView.builder(
          controller: _pageController,
          itemCount: count,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (context, i) {
            return InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: widget.urls[i],
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (_, _) => const Center(
                    child: CircularProgressIndicator(color: Colors.white54),
                  ),
                  errorWidget: (_, _, _) => const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white54,
                      size: 48,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
