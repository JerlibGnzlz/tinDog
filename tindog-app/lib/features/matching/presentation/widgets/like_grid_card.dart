import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/discover_candidate.dart';

class LikeGridCard extends StatelessWidget {
  const LikeGridCard({
    super.key,
    required this.item,
    this.onTap,
    this.onLikeBack,
    this.liking = false,
  });

  final LikeListItem item;
  final VoidCallback? onTap;
  final VoidCallback? onLikeBack;
  final bool liking;

  @override
  Widget build(BuildContext context) {
    final title = item.age != null ? '${item.name}, ${item.age}' : item.name;
    final photo = item.photoUrls.isNotEmpty ? item.photoUrls.first : null;
    final canLikeBack = onLikeBack != null && !item.matched;
    final distance = item.distanceLabel;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: item.matched
                  ? AppColors.primary.withValues(alpha: 0.55)
                  : AppColors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (photo != null)
                  CachedNetworkImage(
                    imageUrl: photo,
                    fit: BoxFit.cover,
                    placeholder: (_, _) =>
                        const ColoredBox(color: AppColors.border),
                    errorWidget: (_, _, _) => const ColoredBox(
                      color: AppColors.border,
                      child: Icon(Icons.pets, color: AppColors.textSecondary),
                    ),
                  )
                else
                  const ColoredBox(
                    color: AppColors.border,
                    child: Icon(Icons.pets, color: AppColors.textSecondary),
                  ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x14000000),
                        Color(0x00000000),
                        Color(0xCC222222),
                      ],
                      stops: [0, 0.42, 1],
                    ),
                  ),
                ),
                if (item.matched || canLikeBack)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _StatusChip(
                      label: item.matched ? 'Match' : 'Te dio like',
                      icon: item.matched
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      emphasized: item.matched,
                    ),
                  ),
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 10,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              canLikeBack
                                  ? 'Tocá ♥ para match'
                                  : item.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.92),
                                fontSize: 12,
                                height: 1.1,
                              ),
                            ),
                            if (distance != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                distance,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _ActionButton(
                        liking: liking,
                        canLikeBack: canLikeBack,
                        matched: item.matched,
                        onPressed: liking
                            ? null
                            : (canLikeBack ? onLikeBack : onTap),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.icon,
    required this.emphasized,
  });

  final String label;
  final IconData icon;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: emphasized
            ? AppColors.primary
            : Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: emphasized
              ? AppColors.primaryDark
              : Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.liking,
    required this.canLikeBack,
    required this.matched,
    required this.onPressed,
  });

  final bool liking;
  final bool canLikeBack;
  final bool matched;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: canLikeBack
                ? AppColors.primary
                : AppColors.card.withValues(alpha: 0.94),
            shape: BoxShape.circle,
            border: Border.all(
              color: canLikeBack
                  ? AppColors.primaryDark
                  : AppColors.border,
            ),
            boxShadow: canLikeBack
                ? [
                    BoxShadow(
                      color: AppColors.primaryDark.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: liking
              ? const Padding(
                  padding: EdgeInsets.all(11),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  matched || canLikeBack
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 20,
                  color: canLikeBack
                      ? Colors.white
                      : matched
                          ? AppColors.accent
                          : AppColors.primaryDark,
                ),
        ),
      ),
    );
  }
}
