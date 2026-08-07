import '../../../shared/models/swipe_preview_media.dart';

/// Candidato del deck de discovery (otra mascota, no la tuya).
class DiscoverCandidate {
  const DiscoverCandidate({
    required this.id,
    required this.name,
    required this.photoUrls,
    this.age,
    this.breed,
    this.bio,
    this.location,
    this.distanceKm,
    this.isActive = true,
    this.ownerUserId,
  });

  final String id;
  final String name;
  final List<String> photoUrls;
  final int? age;
  final String? breed;
  final String? bio;
  final String? location;
  final double? distanceKm;
  final bool isActive;
  /// Dueño tinDog / id de usuario Stream (para online).
  final String? ownerUserId;

  factory DiscoverCandidate.fromJson(Map<String, dynamic> json) {
    final urls = (json['photoUrls'] as List<dynamic>? ?? const [])
        .map((e) => e as String)
        .where((u) => u.trim().isNotEmpty)
        .toList(growable: false);

    return DiscoverCandidate(
      id: json['id'] as String,
      name: json['name'] as String,
      age: (json['age'] as num?)?.toInt(),
      breed: json['breed'] as String?,
      bio: json['bio'] as String?,
      location: json['location'] as String?,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      isActive: json['isActive'] as bool? ?? true,
      ownerUserId: json['ownerUserId'] as String?,
      photoUrls: urls,
    );
  }

  List<SwipePreviewMediaItem> get mediaItems =>
      photoUrls.map(SwipePreviewMediaItem.photo).toList(growable: false);

  String? get distanceLabel {
    if (distanceKm == null) return null;
    final km = distanceKm!;
    if (km < 1) {
      final meters = (km * 1000).round();
      return 'A $meters m de distancia';
    }
    final rounded = km < 10 ? km.toStringAsFixed(1) : km.round().toString();
    return 'A $rounded km de distancia';
  }

  String? get locationLabel {
    final loc = location?.trim();
    if (loc == null || loc.isEmpty) return null;
    return loc.startsWith('Vive') ? loc : 'Vive en $loc';
  }
}

class LikeResult {
  const LikeResult({
    required this.liked,
    required this.matched,
  });

  final bool liked;
  final bool matched;

  factory LikeResult.fromJson(Map<String, dynamic> json) {
    return LikeResult(
      liked: json['liked'] as bool? ?? true,
      matched: json['matched'] as bool? ?? false,
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
    super.age,
    super.breed,
    super.bio,
    super.location,
    super.distanceKm,
    super.isActive,
    super.ownerUserId,
  });

  final DateTime likedAt;
  final bool matched;

  factory LikeListItem.fromJson(Map<String, dynamic> json) {
    final base = DiscoverCandidate.fromJson(json);
    return LikeListItem(
      id: base.id,
      name: base.name,
      photoUrls: base.photoUrls,
      age: base.age,
      breed: base.breed,
      bio: base.bio,
      location: base.location,
      distanceKm: base.distanceKm,
      isActive: base.isActive,
      ownerUserId: base.ownerUserId,
      likedAt: DateTime.tryParse(json['likedAt'] as String? ?? '') ??
          DateTime.now(),
      matched: json['matched'] as bool? ?? false,
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
