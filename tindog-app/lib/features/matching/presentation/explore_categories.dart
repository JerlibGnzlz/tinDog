import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'discover_filters.dart';

class ExploreCategory {
  const ExploreCategory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    this.mode,
    this.countLabel,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  /// Si es null → teaser de servicios (próximamente).
  final DiscoverMode? mode;
  final String? countLabel;

  bool get opensDiscover => mode != null;
}

/// Atajos → modos de Desliza.
const exploreDogShortcuts = <ExploreCategory>[
  ExploreCategory(
    id: 'near',
    title: 'Cerca de vos',
    subtitle: 'Mascotas a poca distancia',
    icon: Icons.near_me_rounded,
    accent: Color(0xFF5B8FA8),
    mode: DiscoverMode.near,
    countLabel: 'GPS',
  ),
  ExploreCategory(
    id: 'breed',
    title: 'Misma raza',
    subtitle: 'Perfiles parecidos a tu mascota',
    icon: Icons.pets_rounded,
    accent: AppColors.primary,
    mode: DiscoverMode.breed,
    countLabel: 'Raza',
  ),
  ExploreCategory(
    id: 'for_you',
    title: 'Para ti',
    subtitle: 'Sugerencias personalizadas',
    icon: Icons.auto_awesome_rounded,
    accent: AppColors.accent,
    mode: DiscoverMode.forYou,
    countLabel: 'Match',
  ),
  ExploreCategory(
    id: 'with_videos',
    title: 'Con videos',
    subtitle: 'Solo quien tiene clip',
    icon: Icons.videocam_rounded,
    accent: const Color(0xFF6B8F9A),
    mode: DiscoverMode.withVideos,
    countLabel: 'Clip',
  ),
];

/// Servicios del barrio (UI only — Places más adelante).
const exploreServiceTeasers = <ExploreCategory>[
  ExploreCategory(
    id: 'vets',
    title: 'Veterinarias',
    subtitle: 'Clínicas cerca tuyo',
    icon: Icons.medical_services_rounded,
    accent: Color(0xFF5B8FA8),
    countLabel: 'Pronto',
  ),
  ExploreCategory(
    id: 'walks',
    title: 'Paseos',
    subtitle: 'Parques y dog parks',
    icon: Icons.directions_walk_rounded,
    accent: AppColors.primary,
    countLabel: 'Pronto',
  ),
  ExploreCategory(
    id: 'shelters',
    title: 'Refugios',
    subtitle: 'Adopción y protectoras',
    icon: Icons.home_rounded,
    accent: Color(0xFFC4A574),
    countLabel: 'Pronto',
  ),
  ExploreCategory(
    id: 'petshops',
    title: 'PET shops',
    subtitle: 'Tiendas de mascotas',
    icon: Icons.storefront_rounded,
    accent: AppColors.accent,
    countLabel: 'Pronto',
  ),
];
