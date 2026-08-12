/// Modo de discovery (tabs Desliza).
enum DiscoverMode {
  forYou,
  near,
  breed,
  withVideos,
}

extension DiscoverModeApi on DiscoverMode {
  String get apiValue => switch (this) {
        DiscoverMode.forYou => 'for_you',
        DiscoverMode.near => 'near',
        DiscoverMode.breed => 'breed',
        DiscoverMode.withVideos => 'with_videos',
      };

  String get label => switch (this) {
        DiscoverMode.forYou => 'Para ti',
        DiscoverMode.near => 'Cerca',
        DiscoverMode.breed => 'Razas',
        DiscoverMode.withVideos => 'Videos',
      };
}

class DiscoverFilters {
  const DiscoverFilters({
    this.mode = DiscoverMode.forYou,
    this.breed,
    this.minAge,
    this.maxAge,
    this.maxKm = 50,
  });

  final DiscoverMode mode;
  final String? breed;
  final int? minAge;
  final int? maxAge;
  final int maxKm;

  DiscoverFilters copyWith({
    DiscoverMode? mode,
    String? breed,
    int? minAge,
    int? maxAge,
    int? maxKm,
    bool clearBreed = false,
    bool clearMinAge = false,
    bool clearMaxAge = false,
  }) {
    return DiscoverFilters(
      mode: mode ?? this.mode,
      breed: clearBreed ? null : (breed ?? this.breed),
      minAge: clearMinAge ? null : (minAge ?? this.minAge),
      maxAge: clearMaxAge ? null : (maxAge ?? this.maxAge),
      maxKm: maxKm ?? this.maxKm,
    );
  }

  bool get hasExtraFilters =>
      (breed != null && breed!.trim().isNotEmpty) ||
      minAge != null ||
      maxAge != null ||
      maxKm != 50;

  String emptyMessage({required bool hasGps, required bool hasOwnBreed}) {
    switch (mode) {
      case DiscoverMode.near:
        if (!hasGps) {
          return 'Activá tu ubicación GPS en el perfil para ver mascotas cerca.';
        }
        return 'No hay perfiles dentro de $maxKm km por ahora.';
      case DiscoverMode.breed:
        if ((breed == null || breed!.trim().isEmpty) && !hasOwnBreed) {
          return 'Elegí una raza en Filtros o completá la raza de tu mascota.';
        }
        return 'No hay perfiles de esa raza por ahora.';
      case DiscoverMode.withVideos:
        return 'Nadie subió un clip todavía. Volvé más tarde o subí el tuyo en Perfil → Videos.';
      case DiscoverMode.forYou:
        return 'No hay más perfiles por ahora. Volvé más tarde o completá tu perfil para aparecer ante otros.';
    }
  }

  @override
  bool operator ==(Object other) {
    return other is DiscoverFilters &&
        other.mode == mode &&
        other.breed == breed &&
        other.minAge == minAge &&
        other.maxAge == maxAge &&
        other.maxKm == maxKm;
  }

  @override
  int get hashCode => Object.hash(mode, breed, minAge, maxAge, maxKm);
}

/// Razas sugeridas para el picker (texto libre también permitido).
const kSuggestedBreeds = <String>[
  'Mestizo',
  'Labrador',
  'Golden Retriever',
  'Bulldog',
  'Poodle',
  'Beagle',
  'Pastor Alemán',
  'Chihuahua',
  'Yorkshire',
  'Boxer',
  'Dálmata',
  'Husky',
  'Caniche',
  'Pug',
  'Doberman',
];
