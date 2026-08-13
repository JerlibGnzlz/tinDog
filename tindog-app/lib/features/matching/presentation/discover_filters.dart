import 'package:flutter/material.dart';

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

  /// Resumen legible de filtros extra (chips / empty).
  String get activeSummary {
    final parts = <String>[];
    final b = breed?.trim();
    if (b != null && b.isNotEmpty) parts.add(b);
    if (minAge != null || maxAge != null) {
      parts.add('${minAge ?? 0}–${maxAge ?? 20} años');
    }
    if (maxKm != 50) parts.add('$maxKm km');
    return parts.join(' · ');
  }

  /// Solo cambia el modo (mantiene raza/edad/km).
  DiscoverFilters withMode(DiscoverMode next) => copyWith(mode: next);

  /// Quita raza, edad y radio custom; deja el modo.
  DiscoverFilters withoutExtras() => DiscoverFilters(mode: mode);

  /// «Para ti» limpio: sin filtros extra.
  DiscoverFilters get asCleanForYou => const DiscoverFilters();

  /// Al cambiar de pestaña: Para ti / Videos arrancan limpios.
  DiscoverFilters forModeChange(DiscoverMode next) {
    if (next == DiscoverMode.forYou) return asCleanForYou;
    if (next == DiscoverMode.withVideos) {
      return const DiscoverFilters(mode: DiscoverMode.withVideos);
    }
    return withMode(next);
  }

  /// Copy + acciones del empty state según modo (Cerca / Razas / Videos…).
  DiscoverEmptySpec emptySpec({
    required bool hasGps,
    required bool hasOwnBreed,
  }) {
    // Casos que no se resuelven limpiando filtros.
    if (mode == DiscoverMode.near && !hasGps) {
      return const DiscoverEmptySpec(
        title: 'Falta tu ubicación',
        subtitle:
            'Activá el GPS en tu perfil para ver mascotas cerca de vos.',
        icon: Icons.location_off_rounded,
        primaryLabel: 'Activar GPS',
        primaryAction: DiscoverEmptyPrimary.openLocation,
        secondaryLabel: 'Ver Para ti',
        secondaryAction: DiscoverEmptySecondary.forYou,
      );
    }
    if (mode == DiscoverMode.breed &&
        (breed == null || breed!.trim().isEmpty) &&
        !hasOwnBreed) {
      return const DiscoverEmptySpec(
        title: 'Elegí una raza',
        subtitle:
            'Indicá la raza en Filtros o completá la de tu mascota para buscar iguales.',
        icon: Icons.pets_rounded,
        primaryLabel: 'Elegir raza',
        primaryAction: DiscoverEmptyPrimary.openFilters,
        secondaryLabel: 'Ver Para ti',
        secondaryAction: DiscoverEmptySecondary.forYou,
      );
    }

    // Filtros extra activos → el vacío suele ser por eso (muy confuso en Para ti).
    if (hasExtraFilters) {
      final summary = activeSummary;
      return DiscoverEmptySpec(
        title: 'Nadie con estos filtros',
        subtitle: summary.isEmpty
            ? 'Tus filtros están dejando el feed vacío. Limpiálos o editálos.'
            : 'Activos: $summary. Limpiálos o editálos para ver más perfiles.',
        icon: Icons.filter_alt_off_rounded,
        primaryLabel: 'Limpiar filtros',
        primaryAction: DiscoverEmptyPrimary.clearFilters,
        secondaryLabel: 'Editar filtros',
        secondaryAction: DiscoverEmptySecondary.openFilters,
      );
    }

    switch (mode) {
      case DiscoverMode.near:
        return DiscoverEmptySpec(
          title: 'Nadie cerca por ahora',
          subtitle:
              'No hay perfiles dentro de $maxKm km. Ampliá el radio o mirá otras sugerencias.',
          icon: Icons.near_me_rounded,
          primaryLabel: 'Ampliar radio',
          primaryAction: DiscoverEmptyPrimary.openFilters,
          secondaryLabel: 'Ver Para ti',
          secondaryAction: DiscoverEmptySecondary.forYou,
        );
      case DiscoverMode.breed:
        final label = (breed != null && breed!.trim().isNotEmpty)
            ? breed!.trim()
            : 'esa raza';
        return DiscoverEmptySpec(
          title: 'Sin perfiles de $label',
          subtitle:
              'Todavía no hay dueños con esa raza. Probá otra o volvé más tarde.',
          icon: Icons.pets_rounded,
          primaryLabel: 'Cambiar raza',
          primaryAction: DiscoverEmptyPrimary.openFilters,
          secondaryLabel: 'Ver Para ti',
          secondaryAction: DiscoverEmptySecondary.forYou,
        );
      case DiscoverMode.withVideos:
        return const DiscoverEmptySpec(
          title: 'Todavía no hay clips',
          subtitle:
              'Sé de los primeros: un video corto hace que tu perfil destaque en Desliza.',
          icon: Icons.videocam_rounded,
          primaryLabel: 'Subir mi video',
          primaryAction: DiscoverEmptyPrimary.openVideos,
          secondaryLabel: 'Ver Para ti',
          secondaryAction: DiscoverEmptySecondary.forYou,
        );
      case DiscoverMode.forYou:
        return const DiscoverEmptySpec(
          title: 'Por ahora no hay más perfiles',
          subtitle:
              'Completá tu perfil o volvé un rato más tarde: van apareciendo dueños nuevos.',
          icon: Icons.auto_awesome_rounded,
          primaryLabel: 'Actualizar',
          primaryAction: DiscoverEmptyPrimary.reload,
          secondaryLabel: 'Completar perfil',
          secondaryAction: DiscoverEmptySecondary.openProfile,
        );
    }
  }

  String emptyMessage({required bool hasGps, required bool hasOwnBreed}) {
    return emptySpec(hasGps: hasGps, hasOwnBreed: hasOwnBreed).subtitle;
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

enum DiscoverEmptyPrimary {
  reload,
  openLocation,
  openFilters,
  openVideos,
  clearFilters,
}

enum DiscoverEmptySecondary {
  forYou,
  openFilters,
  openProfile,
}

class DiscoverEmptySpec {
  const DiscoverEmptySpec({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.primaryLabel,
    required this.primaryAction,
    this.secondaryLabel,
    this.secondaryAction,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String primaryLabel;
  final DiscoverEmptyPrimary primaryAction;
  final String? secondaryLabel;
  final DiscoverEmptySecondary? secondaryAction;
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
