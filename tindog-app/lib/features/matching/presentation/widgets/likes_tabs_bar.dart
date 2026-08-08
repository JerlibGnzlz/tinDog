import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

enum LikesTabKind { received, sent, topPicks }

class LikesTabsBar extends StatelessWidget {
  const LikesTabsBar({
    super.key,
    required this.tab,
    required this.receivedCount,
    required this.onChanged,
  });

  final LikesTabKind tab;
  final int receivedCount;
  final ValueChanged<LikesTabKind> onChanged;

  String get _receivedLabel {
    if (receivedCount <= 0) return 'Likes';
    if (receivedCount == 1) return '1 Like';
    return '$receivedCount Likes';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              _TabChip(
                label: _receivedLabel,
                selected: tab == LikesTabKind.received,
                onTap: () => onChanged(LikesTabKind.received),
              ),
              _TabChip(
                label: 'Enviados',
                selected: tab == LikesTabKind.sent,
                onTap: () => onChanged(LikesTabKind.sent),
              ),
              _TabChip(
                label: 'Top Picks',
                selected: tab == LikesTabKind.topPicks,
                onTap: () => onChanged(LikesTabKind.topPicks),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.22)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? AppColors.primaryDark
                      : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
