import '../../../shared/models/swipe_preview_media.dart';

class DiscoverVideoClip {
  const DiscoverVideoClip({required this.url, this.durationSec});

  final String url;
  final int? durationSec;

  factory DiscoverVideoClip.fromJson(Map<String, dynamic> json) {
    return DiscoverVideoClip(
      url: (json['url'] as String? ?? '').trim(),
      durationSec: (json['durationSec'] as num?)?.toInt(),
    );
  }
}

/// Candidato del deck de discovery (otra mascota, no la tuya).
class DiscoverCandidate {
  const DiscoverCandidate({
    required this.id,
    required this.name,
    required this.photoUrls,
    this.videos = const [],
    this.age,
    this.breed,
    this.bio,
    this.location,
    this.distanceKm,
    this.isActive = true,
    this.ownerUserId,
    this.ownerName,
    this.ownerAvatarUrl,
    this.ownerGoogleLinked = false,
  });

  final String id;
  final String name;
  final List<String> photoUrls;
  final List<DiscoverVideoClip> videos;
  final int? age;
  final String? breed;
  /// Bio del dueño (Datos personales), visible a otros.
  final String? bio;
  final String? location;
  final double? distanceKm;
  final bool isActive;
  /// Dueño tinDog / id de usuario Stream (para online).
  final String? ownerUserId;
  final String? ownerName;
  final String? ownerAvatarUrl;
  final bool ownerGoogleLinked;

  factory DiscoverCandidate.fromJson(Map<String, dynamic> json) {
    final urls = (json['photoUrls'] as List<dynamic>? ?? const [])
        .map((e) => e as String)
        .where((u) => u.trim().isNotEmpty)
        .toList(growable: false);

    final videos = (json['videos'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(DiscoverVideoClip.fromJson)
        .where((v) => v.url.isNotEmpty)
        .toList(growable: false);

    return DiscoverCandidate(
      id: json['id'] as String,
      name: json['name'] as String,
      age: (json['age'] as num?)?.toInt(),
      breed: json['breed'] as String?,
      bio: json['bio'] as String?,
      location: json['location'] as String?,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      isActive: json['isActive'] as bool? ?? false,
      ownerUserId: json['ownerUserId'] as String?,
      ownerName: (json['ownerName'] as String?)?.trim(),
      ownerAvatarUrl: (json['ownerAvatarUrl'] as String?)?.trim(),
      ownerGoogleLinked: json['ownerGoogleLinked'] as bool? ?? false,
      photoUrls: urls,
      videos: videos,
    );
  }

  /// Fotos primero, luego videos de perfil.
  List<SwipePreviewMediaItem> get mediaItems => [
        ...photoUrls.map(SwipePreviewMediaItem.photo),
        ...videos.map(
          (v) => SwipePreviewMediaItem.video(
            url: v.url,
            durationSec: v.durationSec,
          ),
        ),
      ];

  /// Barrio/ciudad corto (sin provincia) para la card.
  String? get shortLocation {
    var loc = location?.trim();
    if (loc == null || loc.isEmpty) return null;
    final lower = loc.toLowerCase();
    if (lower.startsWith('vive en ')) {
      loc = loc.substring(8).trim();
    }
    final first = loc.split(',').first.trim();
    return first.isEmpty ? loc : first;
  }

  /// Distancia amable (bandas, sin metros exactos que asusten).
  String? get distanceLabel {
    if (distanceKm == null) return null;
    final km = distanceKm!;
    if (km < 0.25) return 'Muy cerca · a menos de 250 m';
    if (km < 1) return 'A menos de 1 km';
    if (km < 3) {
      final tenths = (km * 10).round() / 10;
      final pretty = tenths == tenths.roundToDouble()
          ? tenths.toInt().toString()
          : tenths.toStringAsFixed(1);
      return 'A unos $pretty km';
    }
    if (km < 15) {
      return 'A ${km < 10 ? km.toStringAsFixed(1) : km.round().toString()} km';
    }
    return 'A ${km.round()} km';
  }

  /// Tip de playdate cuando la distancia invita a verse.
  String? get proximityTip {
    if (distanceKm == null) return null;
    final km = distanceKm!;
    if (km < 1) return 'Ideal para un playdate cerca';
    if (km < 5) return 'Buena distancia para un paseo juntos';
    return null;
  }

  String? get locationLabel {
    final short = shortLocation;
    if (short == null) return null;
    return 'Vive en $short';
  }
}

class LikeResult {
  const LikeResult({
    required this.liked,
    required this.matched,
    this.matchId,
  });

  final bool liked;
  final bool matched;
  /// Id del match cuando `matched` es true (`POST /likes` → `match.id`).
  final String? matchId;

  factory LikeResult.fromJson(Map<String, dynamic> json) {
    final match = json['match'];
    String? matchId;
    if (match is Map<String, dynamic>) {
      matchId = match['id'] as String?;
    }
    return LikeResult(
      liked: json['liked'] as bool? ?? true,
      matched: json['matched'] as bool? ?? false,
      matchId: matchId,
    );
  }
}

class LikeListItem extends DiscoverCandidate {
  const LikeListItem({
    required super.id,
    required super.name,
    required super.photoUrls,
    required this.likedAt,
    required this.matched,
    this.matchId,
    super.videos,
    super.age,
    super.breed,
    super.bio,
    super.location,
    super.distanceKm,
    super.isActive,
    super.ownerUserId,
    super.ownerName,
    super.ownerAvatarUrl,
    super.ownerGoogleLinked,
  });

  final DateTime likedAt;
  final bool matched;
  final String? matchId;

  factory LikeListItem.fromJson(Map<String, dynamic> json) {
    final base = DiscoverCandidate.fromJson(json);
    return LikeListItem(
      id: base.id,
      name: base.name,
      photoUrls: base.photoUrls,
      videos: base.videos,
      age: base.age,
      breed: base.breed,
      bio: base.bio,
      location: base.location,
      distanceKm: base.distanceKm,
      isActive: base.isActive,
      ownerUserId: base.ownerUserId,
      ownerName: base.ownerName,
      ownerAvatarUrl: base.ownerAvatarUrl,
      ownerGoogleLinked: base.ownerGoogleLinked,
      likedAt: DateTime.tryParse(json['likedAt'] as String? ?? '') ??
          DateTime.now(),
      matched: json['matched'] as bool? ?? false,
      matchId: json['matchId'] as String?,
    );
  }

  String get subtitle {
    if (matched) return '¡Es un match!';
    final days = DateTime.now().difference(likedAt).inDays;
    if (days <= 0) return 'Hoy';
    if (days == 1) return 'Hace 1 día';
    return 'Hace $days días';
  }
}

class LikesSummary {
  const LikesSummary({
    required this.receivedCount,
    required this.sentCount,
  });

  final int receivedCount;
  final int sentCount;

  factory LikesSummary.fromJson(Map<String, dynamic> json) {
    return LikesSummary(
      receivedCount: (json['receivedCount'] as num?)?.toInt() ?? 0,
      sentCount: (json['sentCount'] as num?)?.toInt() ?? 0,
    );
  }
}
