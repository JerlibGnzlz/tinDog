import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../explore_categories.dart';

class ExploreCategoryCard extends StatelessWidget {
  const ExploreCategoryCard({
    super.key,
    required this.category,
    required this.onTap,
    this.compact = false,
    this.muted = false,
  });

  final ExploreCategory category;
  final VoidCallback onTap;
  final bool compact;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final accent = muted
        ? category.accent.withValues(alpha: 0.55)
        : category.accent;
    final titleColor =
        muted ? AppColors.textSecondary : AppColors.textPrimary;
    final iconSize = compact ? 32.0 : 42.0;
    final circleSize = compact ? 64.0 : 84.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: muted
                ? AppColors.card.withValues(alpha: 0.85)
                : AppColors.card,
            border: Border.all(
              color: muted
                  ? AppColors.border.withValues(alpha: 0.7)
                  : AppColors.border,
            ),
            boxShadow: muted
                ? null
                : [
                    BoxShadow(
                      color: AppColors.textPrimary.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(14, compact ? 12 : 16, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Center(
                    child: Container(
                      width: circleSize,
                      height: circleSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withValues(alpha: muted ? 0.1 : 0.16),
                      ),
                      child: Icon(
                        category.icon,
                        size: iconSize,
                        color: accent,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: compact ? 8 : 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            category.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: titleColor,
                              fontSize: compact ? 14 : 16,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            category.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textSecondary.withValues(
                                alpha: muted ? 0.85 : 1,
                              ),
                              fontSize: compact ? 11 : 12,
                              height: 1.2,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (category.countLabel != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        category.countLabel!,
                        style: TextStyle(
                          color: muted
                              ? AppColors.primaryDark.withValues(alpha: 0.75)
                              : AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
