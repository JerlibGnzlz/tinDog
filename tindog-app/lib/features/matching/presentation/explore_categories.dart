import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ExploreCategory {
  const ExploreCategory({
    required this.id,
    required this.title,
    required this.icon,
    required this.accent,
    this.countLabel,
  });

  final String id;
  final String title;
  final IconData icon;
  final Color accent;
  final String? countLabel;
}

/// Categorías de Explorar (servicios / lugares para mascotas).
const exploreCategories = <ExploreCategory>[
  ExploreCategory(
    id: 'vets',
    title: 'Veterinarias',
    icon: Icons.medical_services_rounded,
    accent: Color(0xFF5B8FA8),
    countLabel: 'Cerca',
  ),
  ExploreCategory(
    id: 'walks',
    title: 'Paseos',
    icon: Icons.directions_walk_rounded,
    accent: AppColors.primary,
    countLabel: 'Hoy',
  ),
  ExploreCategory(
    id: 'shelters',
    title: 'Refugios',
    icon: Icons.home_rounded,
    accent: Color(0xFFC4A574),
    countLabel: 'Ayudá',
  ),
  ExploreCategory(
    id: 'petshops',
    title: 'PET shops',
    icon: Icons.storefront_rounded,
    accent: AppColors.accent,
    countLabel: 'Locales',
  ),
];
