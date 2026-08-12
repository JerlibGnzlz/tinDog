import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/tindog_empty_state.dart';

class LikesEmptyState extends StatelessWidget {
  const LikesEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.favorite_border_rounded,
    this.primaryLabel = 'Ir a Desliza',
    this.onPrimary,
    this.showDiscoverButton = true,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final bool showDiscoverButton;

  @override
  Widget build(BuildContext context) {
    return TindogEmptyState(
      title: title,
      subtitle: subtitle,
      icon: icon,
      primaryLabel: showDiscoverButton ? primaryLabel : null,
      onPrimary: showDiscoverButton
          ? (onPrimary ?? () => context.go('/discover'))
          : null,
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 96),
    );
  }
}
