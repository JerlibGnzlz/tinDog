class SwipePreviewMediaItem {
  const SwipePreviewMediaItem.photo(this.url)
      : isVideo = false,
        durationSec = null;

  const SwipePreviewMediaItem.video({
    required this.url,
    this.durationSec,
  }) : isVideo = true;

  final String url;
  final bool isVideo;
  final int? durationSec;

  String get thumbnailUrl =>
      isVideo ? cloudinaryVideoPosterUrl(url) : url;
}

/// Frame del segundo 0 como JPG (Cloudinary no sirve .mp4 como imagen en widgets).
String cloudinaryVideoPosterUrl(String videoUrl) {
  const marker = '/video/upload/';
  final index = videoUrl.indexOf(marker);
  if (index == -1) return videoUrl;

  final insertAt = index + marker.length;
  var resourcePath = videoUrl.substring(insertAt);

  final queryIndex = resourcePath.indexOf('?');
  if (queryIndex != -1) {
    resourcePath = resourcePath.substring(0, queryIndex);
  }

  resourcePath = resourcePath.replaceAll(
    RegExp(r'\.(mp4|mov|webm|mkv)$', caseSensitive: false),
    '.jpg',
  );

  if (!resourcePath.toLowerCase().endsWith('.jpg')) {
    resourcePath = '$resourcePath.jpg';
  }

  return '${videoUrl.substring(0, insertAt)}'
      'so_0,w_800,h_800,c_fill,f_jpg/'
      '$resourcePath';
}

String formatMediaDuration(int seconds) {
  final minutes = seconds ~/ 60;
  final remaining = seconds % 60;
  if (minutes == 0) return '${remaining}s';
  return '$minutes:${remaining.toString().padLeft(2, '0')}';
}
